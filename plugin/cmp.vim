vim9script

if get(g:, 'ivim_cmp_loaded', 0)
  finish
endif
g:ivim_cmp_loaded = 1

import autoload '../autoload/cmp/util.vim' as cutil
import autoload '../autoload/cmp/path.vim' as cpath
import autoload '../autoload/cmp/lsp.vim' as clsp

cutil.InitKindHighlightGroups()
# clsp.Setup()

# insert mode
set autocomplete
set autocompletedelay=200
# limit candidates from some sources to specific number (e.g., 5)
set complete=.,w,b^5,u^5,t,i,Fcpath.Completor^5,Fclsp.Completor^10
set completeopt=menu,menuone,noselect,popup
set completepopup=border:round,close:off

inoremap <silent><expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

# command line, :h cmdline-autocompletion
