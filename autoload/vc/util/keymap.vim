vim9script
#==============================================================
# add map through vim-which-key or which-key.nvim
#==============================================================

import autoload "../util/notify.vim"
import autoload "./plug.vim"

# ensure which-key
if !plug.Has('vim-which-key')
  notify.Error('has no which-key plugin')
  finish
endif

# {{{ global variable
var s_desc: dict<dict<any>> = {'n': {}, 'v': {}}
const NEED_ESCAPE_CHAR = ['''']
const WHICH_KEY = {
  '<leader>': g:mapleader,
  '<localleader>': g:maplocalleader,
  '<esc>': '<Esc>',
  '<tab>': '<Tab>',
  '<cr>': '<CR>',
  '<del>': '<Del>',
  '<bs>': '<BS>',
  '<space>': '<Space>'
}
# }}}

#--------------------------------------------------------------
# split keys string to key list
#--------------------------------------------------------------
def Split(key_seq: string): list<string>
  var keys: list<string> = []
  var in_key: bool = false

  var i: number = 0
  while i < len(key_seq)
    var c: string = key_seq[i]
    if c == '<' && match(key_seq, '<[^<]\{-}>', i) == i
      var j: number = stridx(key_seq, '>', i + 1)
      keys += [key_seq[i : j]]
      i = j + 1
    else
      keys += [c]
      i = i + 1
    endif
  endwhile

  return keys
enddef

#deef TestSplit(): void
# echom Split("ab")
# echom Split("<tab><space>abc")
# echom Split("<tab>abc<space>abc")
# echom Split("abc<tab>abc<space>")
# echom Split("abc<tababc<space>")
# echom Split("abc<tab>space>")
# echom Split("abc<sp")
# echom Split("abc>sp")
# echom Split("abc>s>p")
# echom Split("abc<s<p")
# echom Split("abc<<p")
# echom Split("abc>>p")
#enddef
#TestSplit()

def GenDict(mode: string, keys: list<string>): string
  var dict = "s_desc['" .. mode .. "']"
  for k in keys
    if !eval(printf('has_key(%s, "%s")', dict, k))
      exec printf("%s['%s'] = {}", dict, k)
    endif
    dict ..= "['" .. k .. "']"
  endfor
  return dict
enddef

# SetGroup({key_seq}, {group} [, {mode} [, {overwrite}]])
export def SetGroup(key_seq: string, group: string = null_string,
    mode: string = 'n', overwrite: bool = false): void
  var keys: list<string> = Split(key_seq)
  if len(keys) == 0
    notify.Error('{keys} should not be empty')
    return
  endif

  var desc: string = GenDict(mode, keys)
  if !eval('has_key(' .. desc .. ', "name")') || overwrite
    exec printf("%s.name = '%s'", desc,
      empty(group) ? 'which_key_ignore' : ('+' .. group))
  else
    var groups: list<string> = eval('split(' .. desc .. '.name, "[\+/]")')
    map(groups, 'tolower(v:val)')
    if index(groups, tolower(group)) >= 0
      return
    endif
    exec printf("%s.name ..= '%s'", desc, empty(group) ? '' : ('/' .. group))
  endif
enddef

export def SetDesc(key_seq: string, desc_str: string, mode: string = 'n')
  var keys: list<string> = Split(key_seq)
  if len(keys) == 0
    notify.Error('{keys} should not be empty')
    return
  endif

  var desc: string = GenDict(mode, keys)
  exec printf("%s = '%s'", desc,
    empty(desc_str) ? 'which_key_ignore' : desc_str)
enddef

g:imodule#keymap#desc = s_desc
def RegisterWhichKey(): void
  for mode in keys(s_desc)
    for k in keys(s_desc[mode])
      var which_key: string = get(WHICH_KEY, k, k)
      which_key#register(which_key, g:imodule#keymap#desc[mode][k], mode)
      exec printf("%snoremap <silent> %s :<C-u>WhichKey%s '%s'<CR>",
            \ mode, k, (mode ==? 'n' ? '' : 'Visual'), which_key)
    endfor
  endfor
enddef

augroup vc_autoload_util_keymap
  au!
  au VimEnter * RegisterWhichKey()
augroup END
