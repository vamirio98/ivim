vim9script

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


# specify a directory for plugins
var plugDir: string = get(g:, 'vcPlugDir', expand('~/.vim/plugged'))
plug#begin(plugDir)

#--------------------------------------------------------------
# coding
#--------------------------------------------------------------
Plug 'LunarWatcher/auto-pairs'
IncScript site/plug/auto_pairs.vim

Plug 'vamirio98/vim-strip-trailing-whitespace'
IncScript site/plug/strip_trailing_whitespace.vim

IncScript site/plug/matchup.vim
Plug 'andymass/vim-matchup'

# try vim-vsnip
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
IncScript site/plug/ultisnips.vim

Plug 'yegappan/lsp'
IncScript site/plug/lsp.vim


#---------------------------------------------------------------
# debug
#---------------------------------------------------------------
Plug 'puremourning/vimspector'
IncScript site/plug/vimspector.vim


Plug 'monkoose/vim9-stargate'
IncScript site/plug/stargate.vim

Plug 'kshenoy/vim-signature'

# IncScript site/plug/which_key.vim
# IncScript site/plug/floaterm.vim
# TODO: use myself terminal manager

Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
IncScript site/plug/git.vim

# Plug 'justinmk/vim-dirvish'
# IncScript site/plug/dirvish.vim

Plug 'lambdalisue/vim-fern'
IncScript site/plug/fern.vim

Plug 'skywind3000/asyncrun.vim'
Plug 'skywind3000/asynctasks.vim'
IncScript site/plug/asynctasks.vim

Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
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

Plug 'svermeulen/vim-yoink'
IncScript site/plug/yoink.vim

Plug 'ojroques/vim-oscyank', {'branch': 'main'}
IncScript site/plug/oscyank.vim

# Plug 'ludovicchabant/vim-gutentags'
# Plug 'skywind3000/gutentags_plus'
# LoadConf site/plug/tags.vim

# TODO: try https://github.com/itchyny/vim-cursorword
Plug 'sainnhe/gruvbox-material'
IncScript site/plug/gruvbox_material.vim

# Plug 'ryanoasis/vim-devicons'

Plug 'luochen1990/rainbow'
IncScript site/plug/rainbow.vim

Plug 'bfrg/vim-cpp-modern'

Plug 'preservim/vim-indent-guides'
IncScript site/plug/indent_guides.vim

Plug 'itchyny/lightline.vim'
Plug 'mengelbrecht/lightline-bufferline'
IncScript site/plug/lightline.vim

Plug 'azabiong/vim-highlighter'
Plug 'chrisbra/Colorizer'

Plug 'dstein64/vim-startuptime'

# initialize plugin system
plug#end()

if exists('#User#VcPlugLoaded')
    doautocmd <nomodeline> User VcPlugLoaded
endif
