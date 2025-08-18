vim9script

import autoload "../autoload/lib/ui.vim" as ui

if !exists('g:ivim_bundle')
  g:ivim_bundle = [
    'coding',
    'debug',
    'editor',
    'ui',
    'tags',
    'utils',
  ]
endif

def DoLoadConf(script: string)
  exec "augroup ivim_bundle_" .. tr(script, '/.', '__')
  exec "au!"
  exec "au User IvimLoadPost IncScript" script
  exec "augroup END"
enddef
command! -nargs=1 LoadConf DoLoadConf('<args>')

var s_bundle: dict<bool> = null_dict
for key in g:ivim_bundle
  s_bundle[key] = true
endfor

# specify a directory for plugins
var s_bundle_home: string = get(g:, 'ivim_bundle_home', '~/.vim/bundle')
plug#begin(s_bundle_home)

#--------------------------------------------------------------
# coding
#--------------------------------------------------------------
# {{{ coding
if has_key(s_bundle, 'coding')
  Plug 'LunarWatcher/auto-pairs'
  LoadConf site/bundle/auto_pairs.vim

  Plug 'vamirio98/vim-strip-trailing-whitespace'
  LoadConf site/bundle/strip_trailing_whitespace.vim

  Plug 'andymass/vim-matchup'
  LoadConf site/bundle/match_up.vim

  if has('python3')
    Plug 'SirVer/ultisnips'
    Plug 'honza/vim-snippets'
    LoadConf site/bundle/ultisnips.vim
  else
    ui.Error("no python3 support")
  endif

  Plug 'ycm-core/YouCompleteMe'
  # # for lsp config examples
  # Plug 'ycm-core/lsp-examples'
  LoadConf site/bundle/ycm.vim
  #Plug 'neoclide/coc.nvim', {'branch': 'release'}
  #LoadConf site/bundle/coc.vim
endif
# }}}

if has_key(s_bundle, 'debug')
  Plug 'puremourning/vimspector'
  LoadConf site/bundle/vimspector.vim
endif

# {{{ editor
if has_key(s_bundle, 'editor')
  Plug 'monkoose/vim9-stargate'
  LoadConf site/bundle/easy_motion.vim

  Plug 'kshenoy/vim-signature'

  Plug 'liuchengxu/vim-which-key'
  LoadConf site/bundle/which_key.vim

  Plug 'voldikss/vim-floaterm'
  LoadConf site/bundle/floaterm.vim
  # TODO: use myself terminal manager

  Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'
  LoadConf site/bundle/git.vim

  Plug 'justinmk/vim-dirvish'
  LoadConf site/bundle/dirvish.vim

  Plug 'skywind3000/asyncrun.vim'
  Plug 'skywind3000/asynctasks.vim'
  LoadConf site/bundle/asynctasks.vim

  #Plug 'junegunn/fzf'
  #Plug 'junegunn/fzf.vim'
  #LoadConf site/bundle/fzf.vim

  Plug 'Yggdroot/LeaderF', { 'do': ':LeaderfInstallCExtension' }
  Plug 'Yggdroot/LeaderF-marks'
  Plug 'FahimAnayet/LeaderF-map'
  LoadConf site/bundle/leaderf.vim

  # text opeartor
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-speeddating'
  Plug 'svermeulen/vim-yoink'
  LoadConf site/bundle/yoink.vim
endif
# }}}

if has_key(s_bundle, 'tags')
  Plug 'ludovicchabant/vim-gutentags'
  Plug 'skywind3000/gutentags_plus'
  LoadConf site/bundle/tags.vim
endif

# {{{ ui
if has_key(s_bundle, 'ui')
  Plug 'sainnhe/gruvbox-material'
  LoadConf site/bundle/gruvbox_material.vim

  Plug 'ryanoasis/vim-devicons'

  Plug 'luochen1990/rainbow'
  LoadConf site/bundle/rainbow.vim
  Plug 'bfrg/vim-cpp-modern'
  Plug 'preservim/vim-indent-guides'
  LoadConf site/bundle/indent_guides.vim

  Plug 'itchyny/lightline.vim'
  Plug 'mengelbrecht/lightline-bufferline'
  LoadConf site/bundle/lightline.vim

  Plug 'machakann/vim-highlightedyank'
  LoadConf site/bundle/highlightedyank.vim
endif
# }}}

# {{{
if has_key(s_bundle, 'utils')
  Plug 'dstein64/vim-startuptime'
endif
# }}}

# initialize plugin system
plug#end()
