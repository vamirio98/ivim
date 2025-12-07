vim9script

if get(g:, 'vc_plugin_cmp_loaded', 0)
    finish
endif
g:vc_plugin_cmp_loaded = 1

import autoload 'vc/cmp/util.vim' as cutil
import autoload 'vc/cmp/path.vim' as cpath
import autoload 'vc/cmp/lsp.vim' as clsp

augroup VcPluginCmp
    au!
    au VimEnter * cutil.InitKindHighlightGroups()
    au VimEnter * clsp.Setup()
augroup END

# insert mode
set autocomplete
set autocompletedelay=200
set autocompletetimeout=1000
# limit candidates from some sources to specific number (e.g., 5)
set complete=Fclsp.Completor^10,Fcpath.Completor,.,w,b^5,u^5,t,i
set completeopt=menu,menuone,noselect,popup
set completepopup=border:round,close:off

inoremap <silent><expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

# command line, :h cmdline-autocompletion
