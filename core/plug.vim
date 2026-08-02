vim9script

import autoload 'vc/util/plug.vim' as mPlug

# download plug.vim if it doesn't exist yet
if empty(glob(expand('~/.vim/autoload/plug.vim')))
    exec $'silent !curl -fLo {expand('~/.vim/autoload/plug.vim')} --create-dirs'
                \ 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

# run PlugInstall if there are missing plugins
augroup VcCorePlugAutoInstall
  au!
  au VimEnter * if g:plugs->values()->filter('!isdirectory(v:val.dir)')
              \ ->len() > 0
              \ | PlugInstall --sync
              \ | endif
augroup END

if !exists('g:vc_plug')
    g:vc_plug = [
        'debug',
        'editor',
        'ui',
        'tags',
        'utils',
    ]
endif

def DoLoadConf(script: string)
    exec "augroup vc_plug_" .. tr(script, '/.', '__')
    exec "au!"
    exec "au User VcLoadPost IncScript" script
    exec "augroup END"
enddef
command! -nargs=1 LoadConf DoLoadConf('<args>')

var plug: dict<bool> = null_dict
for key in g:vc_plug
    plug[key] = true
endfor

# specify a directory for plugins
var plugHome: string = get(g:, 'vc_plug_home', expand('~/.vim/plugged'))
plug#begin(plugHome)

#--------------------------------------------------------------
# coding
#--------------------------------------------------------------
IncScript site/plug/auto_pairs.vim
IncScript site/plug/strip_trailing_whitespace.vim
IncScript site/plug/matchup.vim
IncScript site/plug/ultisnips.vim
IncScript site/plug/lsp.vim


#---------------------------------------------------------------
# debug
#---------------------------------------------------------------
IncScript site/plug/vimspector.vim


IncScript site/plug/stargate.vim
Plug 'kshenoy/vim-signature'
IncScript site/plug/which_key.vim
IncScript site/plug/floaterm.vim
# TODO: use myself terminal manager

IncScript site/plug/git.vim
IncScript site/plug/dirvish.vim

IncScript site/plug/asynctasks.vim

IncScript site/plug/fzf.vim

# Plug 'Yggdroot/LeaderF', { 'do': ':LeaderfInstallCExtension' }
# Plug 'Yggdroot/LeaderF-marks'
# Plug 'FahimAnayet/LeaderF-map'
# LoadConf site/plug/leaderf.vim

# text opeartor
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-speeddating'
Plug 'tpope/vim-unimpaired'

IncScript site/plug/yoink.vim

# Plug 'ludovicchabant/vim-gutentags'
# Plug 'skywind3000/gutentags_plus'
# LoadConf site/plug/tags.vim

IncScript site/plug/gruvbox_material.vim
Plug 'ryanoasis/vim-devicons'
IncScript site/plug/rainbow.vim
Plug 'bfrg/vim-cpp-modern'
IncScript site/plug/indent_guides.vim
IncScript site/plug/lightline.vim

Plug 'azabiong/vim-highlighter'
Plug 'chrisbra/Colorizer'

Plug 'dstein64/vim-startuptime'

# initialize plugin system
plug#end()
