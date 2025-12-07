vim9script

if exists('g:isession_loaded')
  finish
endif
g:isession_loaded = 1

import autoload "vc/util/interact.vim"
import autoload "vc/util/path.vim"
import autoload "vc/util/project.vim"
import autoload "vc/util/notify.vim"
import autoload "vc/util/plug.vim"
import autoload "vc/util/keymap.vim"

g:vc_cache_dir = get(g:, 'vc_cache_dir', resolve(expand('~/.cache/vim')))
g:vc_session_dir = get(g:, 'vc_session_dir',
  path.Join(g:vc_cache_dir, 'session'))
# auto update session when leave vim
g:vc_auto_update_session = get(g:, 'vc_auto_update_session', 1)

var s_session_dir = resolve(expand(g:vc_session_dir))
var s_auto_update_session = g:vc_auto_update_session

def g:SessionList(arglead: string, ..._): list<string>
  if !isdirectory(s_session_dir)
    return []
  endif

  var files: list<string> = map(
    split(globpath(s_session_dir, arglead .. '*'), '\n'),
    'fnamemodify(v:val, ":t")'
  )
  return files
enddef

def WriteSessionFile(name: string): void
  var new_name: string = fnamemodify(name, ':t')
  exec 'silent mksession!' path.Join(s_session_dir, new_name)
enddef

# SessionSave({bang} [, {name} [, {silent}]])
def g:SessionSave(bang: bool = false, name: string = null_string,
    silent: bool = false): void
  # ensure session directory exists
  if !isdirectory(s_session_dir)
    var choice: number = interact.Confirm(
      s_session_dir .. ' is not exists, create it?', "&Yes\n&No", 1)
    if choice == 1
      silent mkdir(s_session_dir, 'p')
    else
      notify.Error('The session directory does not exist: ' .. s_session_dir)
      return
    endif
  endif

  var new_name: string = name
  if new_name == null
    new_name = interact.Input('Session name: ',
      fnamemodify(project.CurRoot(), ':t'), 'customlist,g:SessionList'
    )
  endif
  if empty(new_name)
    notify.Error('Need session name')
    return
  endif

  var file: string = path.Join(s_session_dir, new_name)

  if filereadable(file) && !bang
    var choice: number = interact.Confirm(
      new_name .. ' is already exist, overwrite?', "&Yes\n&No", 2)
    if choice != 1
      return
    endif
  endif

  WriteSessionFile(new_name)

  if !silent
    notify.Info('Saved session [' .. new_name .. ']')
  endif
enddef

# TODO: support load_last_session
# SessionLoad({load_last_session} [, {name} [, {silent}]])
def g:SessionLoad(load_last_session: bool = false, name: string = null_string,
    silent: bool = false): void
  if !isdirectory(s_session_dir)
    notify.Error('The session direcotry does not exist: ' .. s_session_dir)
    return
  endif

  var new_name: string = name
  if new_name == null
    new_name = interact.Input('Session name: ', '', 'customlist,g:SessionList')
  endif
  if empty(new_name)
    notify.Error('Need session name')
    return
  endif

  var file: string = path.Join(s_session_dir, new_name)
  if !filereadable(file)
    notify.Error('The session file does not exist: ' .. file)
    return
  endif

  # remove all buffers first
  bufdo bd
  exec 'source' file
  if !silent
    notify.Info('Loaded session [' .. new_name .. ']')
  endif
enddef

# SessionDelete({bang} [, {name} [, {silent}]])
def g:SessionDelete(bang: bool = false, name: string = null_string,
    silent: bool = false): void
  if !isdirectory(s_session_dir)
    notify.Error('The session direcotry does not exist: ' .. s_session_dir)
    return
  endif

  var new_name: string = name
  if new_name == null
    new_name = interact.Input('Session name: ', '', 'customlist,g:SessionList')
  endif
  if empty(new_name)
    notify.Error('Need session name')
    return
  endif

  var file: string = path.Join(s_session_dir, new_name)
  if !filereadable(file)
    notify.Error('No such file: ' .. file)
    return
  endif
  if !bang
    var choice: number = interact.Confirm(
      'Delete session ' .. new_name .. '?', "&Yes\n&No", 2)
    if choice != 1
      return
    endif
  endif
  delete(file)
  if !silent
    notify.Warn('Delete session [' .. new_name .. ']')
  endif
enddef

def g:SessionClose(): void
  if exists('v:this_session') && filereadable(v:this_session)
    WriteSessionFile(fnameescape(v:this_session))
    v:this_session = ''
  endif
  bufdo bd
enddef

command! -nargs=? -bar -bang -complete=customlist,g:SessionList
      \ VcSessionSave g:SessionSave(<bang>0, <f-args>)
command! -nargs=? -bar -bang -complete=customlist,g:SessionList
      \ VcSessionLoad g:SessionLoad(<bang>0, <f-args>)
command! -nargs=? -bar -bang -complete=customlist,g:SessionList
      \ VcSessionDelete g:SessionDelete(<bang>0, <f-args>)
command! -nargs=0 -bar VcSessionClose g:SessionClose()
command! -nargs=0 VcRoot notify.Info(project.CurRoot())

augroup vc_plugin_session
  au!
  au VimLeavePre * if g:vc_auto_update_session &&
        \ exists('v:this_session') && filewritable(v:this_session)
    | WriteSessionFile(fnameescape(v:this_session)) | endif
augroup END

# {{{ leaderf integration
if plug.Has('LeaderF')
  nnoremap <leader>sp <Cmd>Leaderf project<CR>
  keymap.SetDesc('<leader>sp', 'Project')

  def LfProjectSource(..._): list<string>
    return g:SessionList('')
  enddef

  def LfPorjectAccept(line: string, arg: any): void
    if !empty(line)
      g:SessionLoad(0, line)
    endif
  enddef

  g:Lf_Extensions = get(g:, 'Lf_Extensions', {})
  g:Lf_Extensions.project = {
    'source': string(function('LfProjectSource'))[10 : -3],
    'accept': string(function('LfPorjectAccept'))[10 : -3],
    'help': 'navigate available project from isession.vim',
  }
endif

# }}}
