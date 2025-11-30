vim9script

import autoload "../../autoload/module/keymap.vim" as keymap
import autoload "../../autoload/lib/path.vim" as path
import autoload "../../autoload/module/plug.vim" as plug

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
  'coc-json', 'coc-clangd',
  'coc-pyright',
  'coc-snippets', 'coc-highlight'
]

# global coc-settings.json
g:coc_config_home = path.Join(g:ivim_home, 'site', 'third_party', 'coc')
# global settings
g:coc_user_config = get(g:, 'coc_user_config', {})
g:coc_user_config['workspace.rootPatterns'] = g:ivim_rootmarkers

# use UltiSnip
if plug.Has('ultisnips')
  g:coc_snippet_next = ''
  g:coc_snippet_prev = ''
  g:coc_selectmode_mapping = 0
else
  g:coc_snippet_next = '<C-j>'
  g:coc_snippet_prev = '<C-k>'
  g:coc_selectmode_mapping = 1
endif

g:coc_status_error_sign = ' '
g:coc_status_warning_sign = ' '
g:coc_notify_error_icon = ''
g:coc_notify_warning_icon = ''
g:coc_notify_info_icon = ''

g:coc_borderchars = ['─', '│', '─', '│', '╭', '╮', '╯', '╰', ]

# {{{ keymap
var SetGroup = keymap.SetGroup
var SetDesc = keymap.SetDesc

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
SetGroup('g', 'goto')

def CocAction(keys: string, ability: string, ...action: list<any>)
  if g:CocHasProvider(ability)
    call(g:CocActionAsync, action)
  else
    feedkeys(keys, 'in')
  endif
enddef

nnoremap gd <ScriptCmd>CocAction('gd', 'definition', ['jumpDefinition'])<CR>
SetDesc('gd', 'Go to Definition')
nnoremap gD <ScriptCmd>CocAction('gD', 'declaration', ['jumpDeclaration'])<CR>
SetDesc('gD', 'Go to Declaration')

nnoremap gi <Cmd>call g:CocActionAsync('jumpImplementation', v:false)<CR>
SetDesc('gi', 'Go to implementation')

nnoremap gr <Cmd>call g:CocActionAsync('jumpUsed', v:false)<CR>
SetDesc('gr', 'Go to References')

nnoremap gy <Cmd>call g:CocActionAsync('jumpTypeDefinition')<CR>
SetDesc('gy', 'Go to Type Definition')

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
nmap [e <Plug>(coc-diagnostic-prev-error)
nmap ]e <Plug>(coc-diagnostic-next-error)
SetDesc('[d', 'Prev Diag')
SetDesc(']d', 'Next Diag')
SetDesc('[e', 'Prev Error')
SetDesc(']e', 'Prev Error')

xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)
SetDesc('if', 'Inside Func', 'v')
SetDesc('af', 'Around Func', 'v')
SetDesc('ic', 'Inside Class', 'v')
SetDesc('ac', 'Around Class', 'v')

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
SetGroup('<leader>c', 'code')

nmap <silent> <leader>ca <Plug>(coc-codeaction)
SetDesc('<leader>ca', 'Code Action (cword)')
xmap <silent> <leader>ca <Plug>(coc-codeaction-selected)
nmap <silent> <leader>cA <Plug>(coc-codeaction-source)
SetDesc('<leader>cA', 'Code Action (document)')

nnoremap <leader>cc <Cmd>call g:CocAction('showIncomingCalls')<CR>
nnoremap <leader>cC <Cmd>call g:CocAction('showOutgoingCalls')<CR>
SetDesc('<leader>cc', 'Show Incoming Call')
SetDesc('<leader>cC', 'Show Outgoing Call')

nnoremap <leader>cd <Cmd>CocDiagnostics<CR>
SetDesc('<leader>cd', 'Show Diagnostics')

nnoremap <leader>cf <Cmd>call g:CocActionAsync('format')<CR>
xmap <leader>cf <Plug>(coc-format-selected)
SetDesc('<leader>cf', 'Foramt')
SetDesc('<leader>cf', 'Foramt', 'v')
nmap <silent> <leader>cF <Plug>(coc-codeaction-refactor)
xmap <silent> <leader>cF <Plug>(coc-codeaction-refactor-selected)
SetDesc('<leader>cF', 'Refactor')
SetDesc('<leader>cF', 'Refactor', 'v')

nmap <silent> <leader>cl <Plug>(coc-codelens-action)
SetDesc('<leader>cl', 'Code Lens Action')
nnoremap <leader>cL <Cmd>CocCommand document.checkBuffer<CR>
SetDesc('<leader>cL', 'Show Lsp Info')

def ToggleOutline(): void
  var winid: number = coc#window#find('cocViewId', 'OUTLINE')
  if winid == -1
    g:CocActionAsync('showOutline')
  else
    g:CocActionAsync('hideOutline')
  endif
enddef
nnoremap <leader>co <ScriptCmd>ToggleOutline()<CR>
SetDesc('<leader>co', 'Toggle Outline')
nnoremap <leader>cO <Cmd>call g:CocAction('organizeImport')<CR>
SetDesc('<leader>cO', 'Organize Import')


nmap <leader>cq <Plug>(coc-fix-current)
SetDesc('<leader>cq', 'Quick Fix')

nmap <leader>cr <Plug>(coc-rename)
SetDesc('<leader>cr', 'Rename Symbol')
nnoremap <leader>cR <Cmd>CocCommand workspace.renameCurrentFile<CR>
SetDesc('<leader>cR', 'Rename Cur File')

nnoremap <leader>cy <Cmd>call g:CocAction('showSuperTypes')<CR>
nnoremap <leader>cY <Cmd>call g:CocAction('showSubTypes')<CR>
SetDesc('<leader>cy', 'Show Super Type')
SetDesc('<leader>cY', 'Show Sub Type')

# }}}

# ui
nnoremap <leader>uh <Cmd>CocCommand document.toggleInlayHint<CR>
SetDesc('<leader>uh', 'Toggle Inlay Hint')
nnoremap <leader>ud <Cmd>call g:CocAction('diagnosticToggle')<CR>
SetDesc('<leader>ud', 'Toggle Diagnostic (Global)')
nnoremap <leader>uD <Cmd>call g:CocAction('diagnosticToggleBuffer')<CR>
SetDesc('<leader>uD', 'Toggle Diagnostic (Cur Buffer)')

# {{{ CocList
SetGroup('<leader>C', 'coc-list')
nnoremap <leader>Cc <Cmd>CocList commands<CR>
SetDesc('<leader>Cc', 'Command')
nnoremap <leader>Cd <Cmd>CocList diagnostics<CR>
SetDesc('<leader>Cd', 'Diags')
nnoremap <leader>Ce <Cmd>CocList extensions<CR>
SetDesc('<leader>Ce', 'Extensions')
nnoremap <leader>Cp <Cmd>CocListResume<CR>
SetDesc('<leader>Cp', 'Resume Lastest Command')

nnoremap <leader>ss <Cmd>CocList outline<CR>
SetDesc('<leader>ss', 'Symbols (Cur File)')
nnoremap <leader>sS <Cmd>CocList -I symbols<CR>
SetDesc('<leader>sS', 'Symbols (Workspace)')
# }}}

# }}}

augroup ivim_coc
  au!
  # Highlight symbol and its references when holding the cursor
  au CursorHold * silent g:CocActionAsync('highlight')
  # Setup formatexpr specified filetype(s)
  au FileType json,typescript setl formatexpr=g:CocAction('formatSelected')
  # Update signature help on jump placeholder
  au User CocJumpPlaceholder g:CocActionAsync('showSignatureHelp')
augroup END
