vim9script

if get(g:, 'vcPluginCmpLoaded', 0)
    finish
endif
g:vcPluginCmpLoaded = 1

import autoload 'cmp/util.vim' as mUtil
import autoload 'cmp/path.vim' as mPath
import autoload 'cmp/lsp.vim' as mLsp
import autoload 'cmp/abbr.vim' as mAbbr
import autoload 'cmp/ultisnips.vim' as mUltisnips

# insert mode
set autocomplete
set autocompletedelay=200
set autocompletetimeout=1000
# limit candidates from some sources to specific number (e.g., 5)
set complete=FmLsp.Completor^10
set complete+=FmPath.Completor
set complete+=FmUltisnips.Completor^5
set complete+=FmAbbr.Completor^5,
set complete+=.,w,b^5,u^5,t,i
set completeopt=menuone,noselect,popup
set completepopup=border:round,close:off

inoremap <silent><expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

# command line, :h cmdline-autocompletion
# command line, :h cmdline-autocompletion {{{ #
set wildmode=noselect:lastused,full
set wildoptions=pum

cnoremap <expr> <Up>   wildmenumode() ? "\<C-e>\<Up>"   : "\<Up>"
cnoremap <expr> <Down> wildmenumode() ? "\<C-e>\<Down>" : "\<Down>"
# }}} command line, :h cmdline-autocompletion #

# fix auto-coplete no trigger when type '.' in c {{{ #
# see: https://github.com/vim/vim/pull/17065#issue-2974794522
# see: https://github.com/vim/vim/pull/17812#issuecomment-3094873516
const kInsTrigger = {
    vim: '\v%(\k|\k\.|\k-\>|[gvbls]:)$',
    c: '\v%(\k|\k\.|\k-\>)$',
    cpp: '\v%(\k|\k\.|\k-\>)$',
    python: '\v%(\k|\k\.)$'
}
g:insTrigger = get(g:, 'insTrigger', {})
g:insTrigger = kInsTrigger->extendnew(g:insTrigger, 'force')

def InsComplete(): void
    if getcharstr(1) == '' && getline('.')->strpart(0, col('.') - 1) =~ b:insTrigger
        SkipTextChangedIEvent()
        feedkeys("\<C-n>", "n")
    endif
enddef

def SkipTextChangedIEvent(): string
    set eventignore+=TextChangedI  # Suppress next event caused by <c-e> (or <c-n> when no matches found)
    timer_start(1, (_) => {
        set eventignore-=TextChangedI
    })
    return ''
enddef

inoremap <silent> <c-e> <c-r>=<SID>SkipTextChangedIEvent()<cr><c-e>

def SetupInsTrigger(): void
    if exists('b:insTrigger')
        return
    endif
    b:insTrigger = get(g:insTrigger, &ft, '\k$')
enddef
# }}} fix auto-coplete no trigger when type '.' in c #

augroup VcPluginCmp
    au!
    au VimEnter * mUtil.InitKindHighlightGroups()
    au VimEnter * mLsp.Setup()
    au BufEnter * SetupInsTrigger()
    au FileType * SetupInsTrigger()
    au TextChangedI * InsComplete()
augroup END
