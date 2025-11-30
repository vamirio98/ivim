vim9script

import autoload "../autoload/lib/ui.vim" as ui

# download plug.vim if it doesn't exist yet
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

# run PlugInstall if there are missing plugins
augroup IvimAutoInstallPlugins
  au!
  au VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)')) > 0
        \| PlugInstall --sync | source $MYVIMRC
        \| endif
augroup END

if !exists('g:ivim_plug')
  g:ivim_plug = [
    'coding',
    'debug',
    'editor',
    'ui',
    'tags',
    'utils',
  ]
endif

def DoLoadConf(script: string)
  exec "augroup ivim_plug_" .. tr(script, '/.', '__')
  exec "au!"
  exec "au User IvimLoadPost IncScript" script
  exec "augroup END"
enddef
command! -nargs=1 LoadConf DoLoadConf('<args>')

var s_plug: dict<bool> = null_dict
for key in g:ivim_plug
  s_plug[key] = true
endfor

# specify a directory for plugins
var s_plug_home: string = get(g:, 'ivim_plug_home', '~/.vim/plugged')
plug#begin(s_plug_home)

#--------------------------------------------------------------
# coding
#--------------------------------------------------------------
# {{{ coding
if has_key(s_plug, 'coding')
  Plug 'LunarWatcher/auto-pairs'
  LoadConf site/plug/auto_pairs.vim

  Plug 'vamirio98/vim-strip-trailing-whitespace'
  LoadConf site/plug/strip_trailing_whitespace.vim

  Plug 'andymass/vim-matchup'
  LoadConf site/plug/match_up.vim

  if has('python3')
    Plug 'SirVer/ultisnips'
    Plug 'honza/vim-snippets'
    LoadConf site/plug/ultisnips.vim
  else
    ui.Error("no python3 support")
  endif

  Plug 'yegappan/lsp'
  LoadConf site/plug/lsp.vim
endif
# }}}

if has_key(s_plug, 'debug')
  Plug 'puremourning/vimspector'
  LoadConf site/plug/vimspector.vim
endif

# {{{ editor
if has_key(s_plug, 'editor')
  Plug 'monkoose/vim9-stargate'
  LoadConf site/plug/easy_motion.vim

  Plug 'kshenoy/vim-signature'

  Plug 'liuchengxu/vim-which-key'
  LoadConf site/plug/which_key.vim

  Plug 'voldikss/vim-floaterm'
  LoadConf site/plug/floaterm.vim
  # TODO: use myself terminal manager

  Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'
  LoadConf site/plug/git.vim

  Plug 'justinmk/vim-dirvish'
  LoadConf site/plug/dirvish.vim

  Plug 'skywind3000/asyncrun.vim'
  Plug 'skywind3000/asynctasks.vim'
  LoadConf site/plug/asynctasks.vim

  #Plug 'junegunn/fzf'
  #Plug 'junegunn/fzf.vim'
  #LoadConf site/plug/fzf.vim

  Plug 'Yggdroot/LeaderF', { 'do': ':LeaderfInstallCExtension' }
  Plug 'Yggdroot/LeaderF-marks'
  Plug 'FahimAnayet/LeaderF-map'
  LoadConf site/plug/leaderf.vim

  # text opeartor
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-speeddating'
  Plug 'tpope/vim-unimpaired'
  Plug 'svermeulen/vim-yoink'
  LoadConf site/plug/yoink.vim
endif
# }}}

if has_key(s_plug, 'tags')
  Plug 'ludovicchabant/vim-gutentags'
  Plug 'skywind3000/gutentags_plus'
  LoadConf site/plug/tags.vim
endif

# {{{ ui
if has_key(s_plug, 'ui')
  Plug 'sainnhe/gruvbox-material'
  LoadConf site/plug/gruvbox_material.vim

  Plug 'ryanoasis/vim-devicons'

  Plug 'luochen1990/rainbow'
  LoadConf site/plug/rainbow.vim
  Plug 'bfrg/vim-cpp-modern'
  Plug 'preservim/vim-indent-guides'
  LoadConf site/plug/indent_guides.vim

  Plug 'itchyny/lightline.vim'
  Plug 'mengelbrecht/lightline-bufferline'
  LoadConf site/plug/lightline.vim

  Plug 'machakann/vim-highlightedyank'
  LoadConf site/plug/highlightedyank.vim
endif
# }}}

# {{{
if has_key(s_plug, 'utils')
  Plug 'dstein64/vim-startuptime'
endif
# }}}

# initialize plugin system
plug#end()
