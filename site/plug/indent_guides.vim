vim9script

import autoload "../../autoload/lib/string.vim" as str
import autoload "../../autoload/module/keymap.vim" as keymap

g:ivim_indent_guide_enabled = get(g:, 'ivim_indent_guide_enabled', 1)

g:indent_guides_default_mapping = 0
g:indent_guides_guide_size = 0
g:indent_guides_start_level = 1
g:indent_guides_enable_on_vim_startup = g:ivim_indent_guide_enabled
g:indent_guides_exclude_buftype = 0
g:indent_guides_exclude_filetypes = ['help', 'startify', 'nerdtree']
g:indent_guides_tab_guides = 1

# {{{ keymap
def StripListchars(listchars: string): string
  var lc: string = listchars
  if str.Contains(lc, 'tab:')
    lc = substitute(lc, '\vtab:.{-},', 'tab:\\ \\ ,', '')
  endif
  if str.Contains(lc, 'lead:')
    lc = substitute(lc, 'lead:.{-},', 'lead:\\ ,', '')
  endif
  return lc
enddef
def IvimIndentGuidesEnable(): void
  g:ivim_indent_guide_enabled = 1
  exec 'IndentGuidesEnable'
  exec 'set listchars=' .. StripListchars(g:ivim_listchars)
enddef
def IvimIndentGuidesDisable(): void
  g:ivim_indent_guide_enabled = 0
  exec 'IndentGuidesDisable'
  exec 'set listchars=' .. g:ivim_listchars
enddef
def g:ToggleIndentGuides(): void
  if g:ivim_indent_guide_enabled
    IvimIndentGuidesDisable()
  else
    IvimIndentGuidesEnable()
  endif
enddef

keymap.SetGroup('<leader>u', 'ui')
keymap.SetDesc('<leader>ui', 'Toggle Indent Guides')
nnoremap <leader>ui <Cmd>call g:ToggleIndentGuides()<CR>
# }}}

g:indent_guides_auto_colors = 0
augroup ivim_indent_guides
  au!
  au VimEnter,ColorScheme * :hi link IndentGuidesOdd DiffAdd
  au VimEnter,ColorScheme * :hi link IndentGuidesEven ToolbarLine
  au VimEnter * if g:ivim_indent_guide_enabled
    | IvimIndentGuidesEnable() | endif
augroup END
