vim9script

import autoload "../autoload/lib/platform.vim" as platform
import autoload "../autoload/lib/path.vim" as path
import autoload "../autoload/lib/ui.vim" as ui

set nocompatible
set backspace=indent,eol,start
set smarttab

set background=light

set nopaste
set fileformats=unix,dos,mac # newline

set autoindent
set cindent

set shiftround # round indent to multiple of 'shiftwidth'
set shiftwidth=4
set softtabstop=4
set noexpandtab
set tabstop=4

set ignorecase # ignore case when search
set smartcase  # unless the search content contains uppercase letters
set hlsearch # highlight the search results
set incsearch # dynamically and incrementally display the search results

if has('multi_byte')
  set termencoding=utf-8  # terminal encoding
  set encoding=utf-8  # internal working encoding
  set fileencoding=utf-8  # default file encoding
  # auto try the following encoding when opening a file
  set fileencodings=ucs-bom,utf-8,gbk,gb18030,big5,euc-jp,latin1
endif

# break at a multibyte character above 255, used for Asian text where every
# character is a word on its own
set formatoptions+=m
# don't insert a space between two multibyte characters (like Chinese) when
# join lines
set formatoptions+=B

set mouse=a

set hidden
set autowrite

set viewoptions=cursor,curdir,folds,slash,unix

set clipboard^=unnamed,unnamedplus
if (!empty($SSH_TTY) || platform.WSL)
  # let vim clipboard sync with system
  # from https://www.zhihu.com/tardis/zm/ans/2156080913?source_id=1003
  def RawEcho(str: string)
    if filewritable('/dev/fd/2')
      writefile([str], '/dev/fd/2', 'b')
    else
      exec "silent! !echo" shellescape(str)
      redraw!
    endif
  enddef

  def Copy(): void
    var c: string = join(v:event.regcontents, "\n")
    var c64: string = system("base64", c)
    var s: string = "\e]52;c;" .. trim(c64) .. "\x07"
    RawEcho(s)
  enddef

  augroup ivim_config_system_clipboard
    au!
    au TextYankPost * Copy()
  augroup END
endif

set completeopt=menu,menuone,noselect
set confirm # confirm to save changes before exiting modified buffer
set formatoptions=jcroqlnt # tcqj
set grepformat=%f:%l:%c:%m
set grepprg=rg\ --vimgrep

set sessionoptions=buffers,curdir,tabpages,winpos,help,folds

set spelllang=en

set noundofile
set updatetime=200 # save swap file and trigger CursorHold

set virtualedit=
set wildmode=longest:full,full

# UI
set cmdheight=1
set display=lastline
set nowrap
set ruler # show cursor position
set cursorline
set colorcolumn=81
set nostartofline  # keep column when switching between buffers
set showcmd  # show command in the last line
set noshowmode
# hide * markup for bold and italic, but not markers with substitutions
set conceallevel=2
set linebreak

set pumheight=10 # maximum number of entries in a popup

set number
set relativenumber
# always show the signcolumn, otherwise it would shift the text each time
set signcolumn=yes

set scrolloff=3
set sidescrolloff=8 # columns of context
set showmatch
set matchtime=3
set list
g:ivim_listchars = 'tab:\│\ ,trail:.,extends:>,precedes:<'
exec 'set listchars=' .. g:ivim_listchars
# error format
set errorformat+=[%f:%l]\ ->\ %m,[%f:%l]:%m
set shortmess+=WIcC
# show search count message
set shortmess-=S

# set navigation and font in GUI
if has('gui_running')
  set guioptions-=m  # remove menu bar.
  set guioptions-=T  # remove toolbar.
  set guioptions-=r  # remove right-hand scrollbar.
  set guioptions-=L  # remove left-hand scrollbar.
  set guioptions-=e  # use a non-GUI tab pages line.
  set guifont=JetBrains_Mono_NL:h13,JetBrainsMonoNL_NFM:h13
  set guifontwide=楷体:h15
endif

set laststatus=2

set splitbelow # put new windows below current
set splitright # put new windows right of current
set splitkeep=screen

set termguicolors # true color support

set winminwidth=5

# fold
exec 'set fillchars=foldopen:,foldclose:,fold:\ ,foldsep:\ ,diff:╱,eob:\ ,vert:\│'
set foldlevel=99

set smoothscroll
set foldmethod=marker
set foldtext=foldtext()

# set <leader> key.
g:mapleader = ' '
g:maplocalleader = '\'

# global variable
g:ivim_rootmarkers = ['.git', '.svn', '.hg', '.root', '.project']

# {{{ ensure all directories is exists
g:ivim_cache_dir = path.Abspath('~/.cache/vim')
g:ivim_bundle_home = path.Abspath('~/.vim/bundle')
g:ivim_swapfile_dir = path.Abspath('~/.cache/vim/swapfiles')

const DIRS = [
  g:ivim_cache_dir,
  g:ivim_bundle_home,
  g:ivim_swapfile_dir,
]
for d in DIRS
  if !isdirectory(d)
    if !mkdir(d, 'p')
      ui.Error("Can not create dir " .. d)
    endif
  endif
endfor
# }}}

# https://stackoverflow.com/a/21026618
# see :h 'directory'
# use trailing '//' to make the swapfile name built from the complete path
# to the file with all path separators substituted to percent '%' signs
exec 'set directory=' .. path.StripSlash(g:ivim_swapfile_dir) .. '//'
