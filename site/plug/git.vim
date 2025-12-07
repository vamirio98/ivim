vim9script

import autoload "vc/util/keymap.vim"
import autoload "vc/util/plug.vim"
import autoload "vc/util/interact.vim"
import autoload "vc/util/python.vim"
import autoload "vc/util/notify.vim"
import autoload "vc/util/project.vim"
import autoload "vc/util/string.vim" as str
import autoload "vc/util/buffer.vim"

g:gitgutter_map_keys = 0

g:gitgutter_sign_priority = 1
g:gitgutter_sign_added = '▎'
g:gitgutter_sign_modified = '▎'
g:gitgutter_sign_removed = ''

g:gitgutter_close_preview_on_escape = 0

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
  var res = python.System('git rev-parse --is-inside-work-tree', dir)
  res = str.Strip(split(res, '\n')[0])
  return res == 'true'
enddef
def GetGitCommits(cwd: string = null_string, reflog: bool = false): list<string>
  var dir: string = cwd == null ? project.CurRoot() : cwd
  if !IsGitRepo(dir)
    return []
  endif

  var cmd: string = reflog ? 'git reflog' : 'git log --oneline'
  var res = python.System(cmd, dir)
  var commits: list<string> = split(res, "\n")
  return commits
enddef
var leaderfGitPreviewBnr: number = buffer.Alloc(true)
augroup VcSitePlugGitLeaderf
    au!
    au VimLeavePre * buffer.Free(leaderfGitPreviewBnr)
augroup END
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
    notify.Warn(printf('Change git diff base to [ %s ]', line), true)
  enddef

  def LfGitDiffBasePreview(_: any, _: any, line: string, _: any): any
    if empty(line)
      return []
    endif

    const bnr: number = leaderfGitPreviewBnr
    const fpath: string = buffer.GetPath(bnr)
    setbufvar(bnr, '&ft', 'git')

    var hash: string = split(line, ' ')[0]
    var log = python.System(printf('git log -n 1 %s', hash))
    buffer.Update(bnr, log)
    return [fpath, 1, ""]
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
      notify.Warn('No commit found')
      return
    endif

    if len(commits) > 9
      commits = commits[0 : 9]
    endif
    commits = map(commits, (index, value) => printf('%d. %s', index + 1, value))
    commits = insert(commits, 'Select new git diff base:')
    var choice: number = interact.Inputlist(commits)
    if choice <= 0 || choice >= len(commits)
      return
    endif
    var token = split(commits[choice], ' ')
    var hash: string = token[1]
    var log: string = commits[choice][len(token[0]) + 1 : -1]
    g:gitgutter_diff_base = hash
    notify.Warn(printf('Change git diff base to [ %s ]', log), true)
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

command! VcGitHunk  GitGutterQuickFix | LeaderfQuickFix
nnoremap <leader>gs <Cmd>VcGitHunk<CR>
SetDesc('<leader>gs', 'Search Hunk')

omap ih <Plug>(GitGutterTextObjectInnerPending)
omap ah <Plug>(GitGutterTextObjectOuterPending)
xmap ih <Plug>(GitGutterTextObjectInnerVisual)
xmap ah <Plug>(GitGutterTextObjectOuterVisual)
SetDesc('ih', 'Inner Hunk', 'v')
SetDesc('ah', 'Outer Hunk', 'v')

augroup vc_site_plug_git
  au!
  au FileType diff nnoremap gq <Cmd>close<CR>
augroup END
# }}}
