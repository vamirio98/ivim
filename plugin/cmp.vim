vim9script

if get(g:, 'vc_plugin_cmp_loaded', 0)
    finish
endif
g:vc_plugin_cmp_loaded = 1

import autoload 'cmp/util.vim' as mUtil
import autoload 'cmp/path.vim' as mPath
import autoload 'cmp/lsp.vim' as mLsp

augroup VcPluginCmp
    au!
    au VimEnter * mUtil.InitKindHighlightGroups()
    au VimEnter * mLsp.Setup()
augroup END

# insert mode
set autocomplete
set autocompletedelay=200
set autocompletetimeout=1000
# limit candidates from some sources to specific number (e.g., 5)
set complete=FmLsp.Completor^10,FmPath.Completor,.,w,b^5,u^5,t,i
set completeopt=menu,menuone,noselect,popup
set completepopup=border:round,close:off

inoremap <silent><expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

# command line, :h cmdline-autocompletion
