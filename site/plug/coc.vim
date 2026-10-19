vim9script

import autoload "util/path.vim" as mPath
import autoload "tool/plug.vim" as mPlug

# some servers have issues with backup files,
# see https://github.com/neoclide/coc.nvim/issues/649
set nobackup
set nowritebackup

# having longer updatetime (default is 4000 ms = 4s) leads to noticeable
# delays and poor user experience
set updatetime=300

# always show the signcolumn, otherwise it would shift the text each time
# diagnostics appear/become resolved
set signcolumn=yes

# ensure the following extensions will be install auto
g:coc_global_extensions = [
    'coc-json',
    'coc-snippets',
    'coc-highlight',
]

# global coc-settings.json
g:coc_config_home = mPath.Joinpath(g:vcHome, 'site', 'coc')
# global settings
g:coc_user_config = get(g:, 'coc_user_config', {})
g:coc_user_config['workspace.rootPatterns'] = g:vcRootmarkers

# use UltiSnip
if mPlug.Has('ultisnips')
    g:coc_snippet_next = ''
    g:coc_snippet_prev = ''
    g:coc_selectmode_mapping = 0
else
    g:coc_snippet_next = '<C-j>'
    g:coc_snippet_prev = '<C-k>'
    g:coc_selectmode_mapping = 1
endif

g:coc_status_error_sign = ''
g:coc_status_warning_sign = ''
g:coc_notify_error_icon = ''
g:coc_notify_warning_icon = ''
g:coc_notify_info_icon = ''

g:coc_borderchars = ['─', '│', '─', '│', '╭', '╮', '╯', '╰', ]

# {{{ keymap
def ShowDoc(): void
    if g:CocHasProvider('hover')
        g:CocActionAsync('doHover')
    else
        feedkeys('K', 'in')
    endif
enddef
nnoremap K <ScriptCmd>ShowDoc()<CR>

nmap <silent> <M-s> <Plug>(coc-range-select)
nmap <silent> <M-S> <Plug>(coc-range-select-backward)
vmap <silent> <M-s> <Plug>(coc-range-select)
vmap <silent> <M-S> <Plug>(coc-range-select-backward)

# {{{ goto
def CocAction(keys: string, ability: string, ...action: list<any>)
    if g:CocHasProvider(ability)
        call(g:CocActionAsync, action)
    else
        feedkeys(keys, 'in')
    endif
enddef

nnoremap gd <ScriptCmd>CocAction('gd', 'definition', ['jumpDefinition'])<CR>
nnoremap gD <ScriptCmd>CocAction('gD', 'declaration', ['jumpDeclaration'])<CR>

nnoremap gi <Cmd>call g:CocActionAsync('jumpImplementation', v:false)<CR>

nnoremap gr <Cmd>call g:CocActionAsync('jumpUsed', v:false)<CR>

nnoremap gy <Cmd>call g:CocActionAsync('jumpTypeDefinition')<CR>

# }}}

# use tab for navigate
inoremap <silent><expr> <Tab> coc#pum#visible() ? coc#pum#next(1) :
            \ (pumvisible() ? "\<C-n>" : "\<Tab>")
inoremap <silent><expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) :
            \ (pumvisible() ? "\<C-p>" : "\<C-h>")
inoremap <silent><expr> <C-n> coc#pum#visible() ? coc#pum#next(1) : "\<C-n>"
inoremap <silent><expr> <C-p> coc#pum#visible() ? coc#pum#prev(1) : "\<C-p>"
inoremap <silent><expr> <down> coc#pum#visible() ? coc#pum#next(1) : "\<down>"
inoremap <silent><expr> <up> coc#pum#visible() ? coc#pum#prev(1) : "\<up>"
inoremap <silent><expr> <PageDown> coc#pum#visible() ? coc#pum#scroll(1) : "\<PageDown>"
inoremap <silent><expr> <PageUp> coc#pum#visible() ? coc#pum#scroll(0) : "\<PageUp>"
inoremap <silent><expr> <C-e> coc#pum#visible() ? coc#pum#cancel() : "\<C-e>"
inoremap <silent><expr> <C-y> coc#pum#visible() ? coc#pum#confirm() : "\<C-y>"

# use <c-space> to toggle completion
if !has('gui_running')
    inoremap <silent><expr> <C-@> coc#pum#visible() ? coc#pum#cancel() : coc#refresh()
else
    inoremap <silent><expr> <C-space> coc#pum#visible() ? coc#pum#cancel() : coc#refresh()
endif

# {{{ navigate
nmap [d <Plug>(coc-diagnostic-prev)
nmap ]d <Plug>(coc-diagnostic-next)

xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

# remap <C-f> and <C-b> to scroll float windows/popups
if has('patch-8.2.0750')
    nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
    nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
    inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
    inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
    vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
    vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif
# }}}

# add current word to multi-cursor
nmap <M-c> <Plug>(coc-cursors-word)
nmap <M-C> <Plug>(coc-cursors-position)
vmap <M-c> <Plug>(coc-cursors-range)

# {{{ code
nmap <silent> <space>ca <Plug>(coc-codeaction)
xmap <silent> <space>ca <Plug>(coc-codeaction-selected)
nmap <silent> <space>cA <Plug>(coc-codeaction-source)

nnoremap <space>cci <Cmd>call g:CocAction('showIncomingCalls')<CR>
nnoremap <space>cco <Cmd>call g:CocAction('showOutgoingCalls')<CR>

nnoremap <space>cd <Cmd>CocDiagnostics<CR>

# nnoremap <space>cf <Cmd>call g:CocActionAsync('format')<CR>
# xmap <space>cf <Plug>(coc-format-selected)

nmap <silent> <space>cl <Plug>(coc-codelens-action)

def ToggleOutline(): void
    var winid: number = coc#window#find('cocViewId', 'OUTLINE')
    if winid == -1
        g:CocActionAsync('showOutline')
    else
        g:CocActionAsync('hideOutline')
    endif
enddef
nnoremap <space>col <ScriptCmd>ToggleOutline()<CR>
nnoremap <space>coi <Cmd>call g:CocAction('organizeImport')<CR>


nmap <space>cq <Plug>(coc-fix-current)

nmap <space>crn <Plug>(coc-rename)
nmap <silent> <space>crf <Plug>(coc-codeaction-refactor)
xmap <silent> <space>crf <Plug>(coc-codeaction-refactor-selected)

nnoremap <space>cyu <Cmd>call g:CocAction('showSuperTypes')<CR>
nnoremap <space>cyd <Cmd>call g:CocAction('showSubTypes')<CR>

# }}}

# ui
nnoremap <space>udg <Cmd>call g:CocAction('diagnosticToggle')<CR>
nnoremap <space>udb <Cmd>call g:CocAction('diagnosticToggleBuffer')<CR>

# {{{ CocList
nnoremap <space>csf <Cmd>CocList outline<CR>
nnoremap <space>csw <Cmd>CocList -I symbols<CR>
# }}}

# }}}

augroup VcSitePlugCoc
    au!
    # Highlight symbol and its references when holding the cursor
    au CursorHold * silent g:CocActionAsync('highlight')
    # Setup formatexpr specified filetype(s)
    au FileType json,typescript setl formatexpr=g:CocAction('formatSelected')
    # Update signature help on jump placeholder
    au User CocJumpPlaceholder g:CocActionAsync('showSignatureHelp')
augroup END
