vim9script

import autoload "../../autoload/module/keymap.vim" as keymap

# for better performace
g:lsp_use_native_client = 1

g:lsp_semantic_enabled = 1

    # `g:lsp_diagnostics_signs_error`, `g:lsp_diagnostics_signs_warning`,
    # `g:lsp_diagnostics_signs_information`, `g:lsp_diagnostics_signs_hint`.
    # `g:lsp_document_code_action_signs_hint`.

g:lsp_diagnostics_virtual_text_prefix = "> "

g:lsp_inlay_hints_enabled = 1

g:lsp_diagnostics_virtual_text_align = "after"

g:lsp_document_symbol_detail = 1

# {{{ keymap
var SetGroup = keymap.SetGroup
var SetDesc = keymap.SetDesc

inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
# make <enter> always input a newline
inoremap <expr> <cr>    pumvisible() ? asyncomplete#close_popup() .. "\<cr>" : "\<cr>"

# For Vim 8 (<c-@> corresponds to <c-space>)
imap <c-@> <Plug>(asyncomplete_force_refresh)

def OnLspBufferEnabled()
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes
  if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif

  nmap <buffer> gd <plug>(lsp-definition)
  nmap <buffer> gs <plug>(lsp-document-symbol-search)
  nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
  nmap <buffer> gr <plug>(lsp-references)
  nmap <buffer> gi <plug>(lsp-implementation)
  nmap <buffer> gt <plug>(lsp-type-definition)
  nmap <buffer> <space>cr <plug>(lsp-rename)
  nmap <buffer> [g <plug>(lsp-previous-diagnostic)
  nmap <buffer> ]g <plug>(lsp-next-diagnostic)
  nmap <buffer> K <plug>(lsp-hover)
  nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
  nnoremap <buffer> <expr><c-b> lsp#scroll(-4)

  g:lsp_format_sync_timeout = 1000

  autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')
enddef
# }}}

# fold
# set foldmethod=expr
#   \ foldexpr=lsp#ui#vim#folding#foldexpr()
#   \ foldtext=lsp#ui#vim#folding#foldtext()

# register asyncomplete-file
augroup ivim_lsp
  au!
  au User lsp_buffer_enabled call OnLspBufferEnabled()
  au User asyncomplete_setup asyncomplete#register_source(asyncomplete#sources#file#get_source_options({
      \ 'name': 'file',
      \ 'allowlist': ['*'],
      \ 'priority': 10,
      \ 'completor': function('asyncomplete#sources#file#completor')
      \ }))
  au User asyncomplete_setup asyncomplete#register_source(asyncomplete#sources#ultisnips#get_source_options({
      \ 'name': 'ultisnips',
      \ 'allowlist': ['*'],
      \ 'completor': function('asyncomplete#sources#ultisnips#completor'),
      \ }))
augroup END
