vim9script

import autoload './autoload/vc/util/log.vim'
import autoload './autoload/vc/util/notify.vim'
import autoload './autoload/vc/util/path.vim'

# global variable
g:vc_listchars = get(g:, 'vc_listchars', 'tab:\│\ ,trail:.,extends:>,precedes:<')
g:vc_rootmarkers = ['.git', '.svn', '.hg', '.root', '.project']
g:vc_cache_dir = path.Abspath('~/.cache/vim')
g:vc_plug_home = path.Abspath('~/.vim/plugged')
g:vc_swapfile_dir = path.Abspath('~/.cache/vim/swapfiles')

log.Info('start loading vc...')

# {{{ ensure all directories is exists
const DIRS = [
    g:vc_cache_dir,
    g:vc_plug_home,
    g:vc_swapfile_dir,
]
for d in DIRS
    if !isdirectory(d)
        if exists('*mkdir')
            if !mkdir(d, 'p')
                notify.Error("can not create dir " .. d)
            endif
        else
            notify.Error($'no dir {d}')
        endif
    endif
endfor
# }}}

var home: string = fnamemodify(resolve(expand('<sfile>:p')), ':h')
g:vc_home = home
command! -nargs=1 IncScript exec 'so' fnameescape(home .. '/<args>')
exec 'set rtp+=' .. fnameescape(home)
set rtp+=~/.vim

# check for depend
const DEPENDENCY: list<string> = ['rg', 'fd']
for dep in DEPENDENCY
    if !executable(dep)
        notify.Error($'no [{dep}] be found in $PATH, some plugins may broken')
    endif
endfor

IncScript config/options.vim
IncScript config/ignores.vim
IncScript config/plug.vim
IncScript config/keymaps.vim
IncScript config/autocmds.vim

doautocmd <nomodeline> User VcLoadPost

log.Info('finish loading vc')
