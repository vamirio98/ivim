vim9script

import autoload "../../autoload/module/keymap.vim" as keymap
import autoload "../../autoload/module/plug.vim" as plug
import autoload "../../autoload/lib/core.vim" as core
import autoload "../../autoload/lib/ui.vim" as ui
import autoload "../../autoload/lib/project.vim" as project
import autoload "../../autoload/lib/string.vim" as str
import autoload "../../autoload/lib/buffer.vim" as buffer

g:gitgutter_map_keys = 0

g:gitgutter_sign_priority = 1
g:gitgutter_sign_added = '▎'
g:gitgutter_sign_modified = '▎'
g:gitgutter_sign_removed = ''

g:gitgutter_close_preview_on_escape = 0

g:gitgutter_grep = 'rg --color=never'

# map {{{
var SetGroup: func = keymap.SetGroup
var SetDesc: func = keymap.SetDesc

SetGroup('<leader>g', 'git')

nmap [c <Plug>(GitGutterPrevHunk)
nmap ]c <Plug>(GitGutterNextHunk)
SetDesc('[c', 'Prev Hunk')
SetDesc(']c', 'Next Hunk')

# {{{ git diff base
def IsGitRepo(cwd: string = null_string): bool
  var dir = cwd == null ? expand('%:h') : cwd
  var res = core.System('git rev-parse --is-inside-work-tree', dir)
  res = str.Strip(split(res, '\n')[0])
  return res == 'true'
enddef
def GetGitCommits(cwd: string = null_string, reflog: bool = false): list<string>
  var dir: string = cwd == null ? project.CurRoot() : cwd
  if !IsGitRepo(dir)
    return []
  endif

  var cmd: string = reflog ? 'git reflog' : 'git log --oneline'
  var res = core.System(cmd, dir)
  var commits: list<string> = split(res, "\n")
  return commits
enddef
if plug.Has('LeaderF')
  def LfGitDiffBaseSource(..._): list<string>
    return GetGitCommits(project.CurRoot())
  enddef

  def LfGitDiffBaseAccept(line: string, arg: any): void
    if empty(line)
      return
    endif

    var token = split(line, ' ')
    var hash: string = token[0]
    g:gitgutter_diff_base = hash
    ui.Warn(printf('Change git diff base to [ %s ]', line), true)
  enddef

  def LfGitDiffBasePreview(_: any, _: any, line: string, _: any): any
    if empty(line)
      return []
    endif

    var bid: number = buffer.Alloc(true, 'leaderf_git_preview')
    var obj: dict<any> = buffer.Object(bid)
    setbufvar(bid, '&ft', 'git')

    var hash: string = split(line, ' ')[0]
    var log = core.System(printf('git log -n 1 %s', hash))
    buffer.Update(bid, log)
    return [obj['path'], 1, ""]
  enddef

  g:Lf_Extensions = get(g:, 'Lf_Extensions', {})
  g:Lf_Extensions.git_diff_base = {
    'source': string(function('LfGitDiffBaseSource'))[10 : -3],
    'accept': string(function('LfGitDiffBaseAccept'))[10 : -3],
    'preview': string(function('LfGitDiffBasePreview'))[10 : -3],
    'highlights_def': {
      'Lf_hl_funcScope': '^\S\+'
    },
    'help': 'navigate git diff base'
  }

  nnoremap <leader>gb <Cmd>Leaderf git_diff_base<CR>
else
  def ChangeGitBase(): void
    var commits: list<string> = GetGitCommits(project.CurRoot())
    if empty(commits)
      ui.Warn('No commit found')
      return
    endif

    if len(commits) > 9
      commits = commits[0 : 9]
    endif
    commits = map(commits, (index, value) => printf('%d. %s', index + 1, value))
    commits = insert(commits, 'Select new git diff base:')
    var choice: number = core.Inputlist(commits)
    if choice <= 0 || choice >= len(commits)
      return
    endif
    var token = split(commits[choice], ' ')
    var hash: string = token[1]
    var log: string = commits[choice][len(token[0]) + 1 : -1]
    g:gitgutter_diff_base = hash
    ui.Warn(printf('Change git diff base to [ %s ]', log), true)
  enddef
  nnoremap <leader>gb <ScriptCmd>ChangeGitBase()<CR>
endif
SetDesc('<leader>gb', 'Change Git Base')
# }}}

def PreviewHunk(): void
  exec 'GitGutterPreviewHunk'
  silent! wincmd P
enddef
nmap <leader>gp <ScriptCmd>PreviewHunk()<CR>
SetDesc('<leader>gp', 'Preview Hunk')

command! IvimGitHunk  GitGutterQuickFix | LeaderfQuickFix
nnoremap <leader>gs <Cmd>IvimGitHunk<CR>
SetDesc('<leader>gs', 'Search Hunk')

omap ih <Plug>(GitGutterTextObjectInnerPending)
omap ah <Plug>(GitGutterTextObjectOuterPending)
xmap ih <Plug>(GitGutterTextObjectInnerVisual)
xmap ah <Plug>(GitGutterTextObjectOuterVisual)
SetDesc('ih', 'Inner Hunk', 'v')
SetDesc('ah', 'Outer Hunk', 'v')

augroup ivim_git
  au!
  au FileType diff nnoremap gq <Cmd>close<CR>
augroup END
# }}}
