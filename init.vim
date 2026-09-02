vim9script

import autoload './autoload/util/log.vim' as mLog
import autoload './autoload/util/msg.vim' as mMsg
import autoload './autoload/util/path.vim' as mPath

# global variable
g:vcListchars = get(g:, 'vc_listchars', 'tab:\│\ ,trail:.,extends:>,precedes:<')
g:vcRootmarkers = ['.git', '.svn', '.hg', '.root', '.project']
g:vcDataDir = mPath.Resolve('~/.local/share/vim/vc')
g:vcCacheDir = mPath.Resolve('~/.cache/vim/vc')
g:vcPlugDir = mPath.Resolve('~/.vim/plugged')
g:vcSwapfileDir = mPath.Resolve('~/.cache/vim/swapfiles')

mLog.Info('start loading vc...')

# {{{ ensure all directories is exists
const kDirs = [
    g:vcDataDir,
    g:vcCacheDir,
    g:vcPlugDir,
    g:vcSwapfileDir,
]
for d in kDirs
    if !isdirectory(d)
        if exists('*mkdir')
            if !mkdir(d, 'p')
                mMsg.Error("can not create dir " .. d)
            endif
        else
            mMsg.Error($'no dir {d}')
        endif
    endif
endfor
# }}}

var s_home: string = fnamemodify(resolve(expand('<sfile>:p')), ':h')
g:vcHome = s_home
command! -nargs=1 IncScript exec 'so' fnameescape(s_home .. '/<args>')
exec 'set rtp+=' .. fnameescape(s_home)
set rtp+=~/.vim

# check for depend
const kDependency: list<string> = ['rg', 'fd']
var s_missDeps: list<string> = []
for dep in kDependency
    if !executable(dep)
        s_missDeps->add(dep)
    endif
endfor
if !empty(s_missDeps)
    mMsg.Error($'no [{s_missDeps}] be found in $PATH, some plugins may broken')
endif

IncScript core/opts/basic.vim
# IncScript core/opts/copy.vim
IncScript core/keymap/basic.vim
IncScript core/ignores.vim
IncScript core/plug.vim
IncScript core/keymap/extend.vim
IncScript core/autocmds/basic.vim
IncScript core/autocmds/extend.vim

if exists('#User#VcLoaded')
    doautocmd <nomodeline> User VcLoaded
endif

mLog.Info('finish loading vc')
