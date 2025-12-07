vim9script

import autoload "vc/util/path.vim"
import autoload "vc/util/os.vim"
import autoload "vc/util/plug.vim"
import autoload "vc/util/keymap.vim"

g:asynctasks_extra_config = get(g:, 'asynctasks_extra_config', [])
g:asynctasks_extra_config += [
  path.Abspath(path.Join(g:vc_home,
    'site/third_party/asynctasks/tasks.ini')
  )
]

g:asyncrun_open = 6
g:asyncrun_rootmarks = g:vc_rootmarkers
g:asyncrun_shell = os.IsWin() ? 'bash' : 'pwsh'
g:asynctasks_rtp_config = "asynctasks.ini"

# python will buffer everything written to stdout when running as a backgroup
# process, this can see the realtime output without calling `flush()`
$PYTHONUNBUFFERED = 1

# {{{ LeaderF integration
# https://github.com/skywind3000/asynctasks.vim/wiki/UI-Integration
if plug.Has('LeaderF')
  nnoremap <leader>pt <Cmd>Leaderf --nowrap task<CR>
  keymap.SetGroup('<leader>p', 'project')
  keymap.SetDesc('<leader>pt', 'Query Tasks')

  def LfTaskSource(..._): list<string>
    var rows: list<list<string>> = asynctasks#source(&columns * 48 / 100)
    var source: list<string> = []
    for row in rows
      var name: string = row[0]
      source += [name .. '  ' .. row[1] .. '  : ' .. row[2]]
    endfor
    return source
  enddef


  def LfTaskAccept(line: string, ..._): void
    var pos: number = stridx(line, '<')
    if pos < 0
      return
    endif
    var name: string = strpart(line, 0, pos)
    name = substitute(name, '^\s*\(.\{-}\)\s*$', '\1', '')
    if name != ''
      exec "AsyncTask " .. name
    endif
  enddef

  def LfTaskDigest(line: string, ..._): list<any>
    var pos: number = stridx(a:line, '<')
    if pos < 0
      return [line, 0]
    endif
    var name: string = strpart(line, 0, pos)
    return [name, 0]
  enddef


  g:Lf_Extensions = get(g:, 'Lf_Extensions', {})
  g:Lf_Extensions.task = {
    'source': string(function('s:LfTaskSource'))[10 : -3],
    'accept': string(function('s:LfTaskAccept'))[10 : -3],
    'get_digest': string(function('s:LfTaskDigest'))[10 : -3],
    'highlights_def': {
        'Lf_hl_funcScope': '^\S\+',
        'Lf_hl_funcDirname': '^\S\+\s*\zs<.*>\ze\s*:',
    },
    'help': 'navigate available tasks from asynctasks.vim',
  }
endif
# }}}
