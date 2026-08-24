vim9script

import autoload "util/proj.vim" as mProj
import autoload 'tool/python.vim' as mPython
import autoload 'util/msg.vim' as mMsg
import autoload 'util/str.vim' as mStr

g:fzf_vim = get(g:, 'fzf_vim', {})

# for color schemes: https://github.com/junegunn/fzf/wiki/Color-schemes
$FZF_DEFAULT_OPTS = [
    '--preview-window="border-rounded" --prompt="> "',
    '--marker=">" --pointer=">" --separator="─" --scrollbar="│"',
    '--layout="default" --height=20',
]->join(' ')

g:fzf_layout = { 'down': '50%' }
# toggle preview window with <Ctrl-/>, show preview window on the right with
# 50% width, but if the width is smaller than 70 columns, it will show above
# the candidate list
g:fzf_vim.preview_window = [ 'right,50%,<70(up,40%)', 'ctrl-/' ]

Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

augroup VcSitePlugFzf
    au!
    au VimEnter * Setup()
augroup END

def FindVcFiles(): void
    exec $'Files {g:vc_home}'
enddef

def FindProjFiles(): void
    var root: string = mProj.Root()
    exec 'Files' root
enddef

# git {{{ #
def IsGitRepo(a_dir: string = null_string): bool
    var dir = a_dir == null ? expand('%:h') : a_dir
    var res = mPython.System('git rev-parse --is-inside-work-tree', dir)
    res = res->split("\n")[0]->mStr.Strip()
    return res == 'true'
enddef

def GetCommits(a_dir: string = null_string, reflog: bool = false): list<string>
    var dir: string = a_dir == null ? mProj.Root() : a_dir
    if !IsGitRepo(dir)
        return []
    endif

    var cmd = reflog ? 'git reflog' : 'git log --oneline'
    var res = mPython.System(cmd, dir)
    return res->split("\n")
enddef

def DoChangeGitDiffBase(line: string): void
    var hash: string = line->split(' ')[0]
    g:gitgutter_diff_base = hash
    mMsg.Info($'Change git diff base to {hash}')
enddef

def ChangeGitDiffBase(): void
    fzf#run(fzf#wrap({
        source: GetCommits(), sink: DoChangeGitDiffBase,
    }))
enddef

noremap <space>gb <scriptcmd>ChangeGitDiffBase()<cr>
# }}} git #

def Setup(): void
# keymap {{{ #
    # SetGroup('<leader>f', 'file')
    nnoremap <space>fc <scriptcmd>FindVcFiles()<cr>
    # SetDesc('<space>fc', 'Conf File')
    nnoremap <space>ff <scriptcmd>FindProjFiles()<cr>
    # SetDesc('<space>ff', 'File (Project Root)')
    nnoremap <space>fF <cmd>Files .<cr>
    # SetDesc('<space>fF', 'File (Cwd)')
    nnoremap <space>fr <cmd>History<cr>
    # SetDesc('<space>fr', 'Recent Files')

    # SetGroup('<space>s', 'search')

    # TODO: gtags
    nnoremap <space>sb <cmd>Buffers<cr>
    nnoremap <space>sc <cmd>Hisotry:<cr>
    nnoremap <space>sh <cmd>Helptags<cr>
    nnoremap <space>sj <cmd>Jumps<cr>
    nnoremap <space>sk <cmd>Maps<cr>
    nnoremap <space>sm <cmd>Marks<cr>
    nnoremap <space>st <cmd>BTags<cr>
    nnoremap <space>sT <cmd>Tags<cr>
# }}} keymap #
enddef
