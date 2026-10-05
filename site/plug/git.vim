vim9script

g:gitgutter_map_keys = 0

g:gitgutter_sign_priority = 1
g:gitgutter_sign_added = '▎'
g:gitgutter_sign_modified = '▎'
g:gitgutter_sign_removed = ''

g:gitgutter_close_preview_on_escape = 0


# keymap {{{ #
nmap [c <Plug>(GitGutterPrevHunk)
nmap ]c <Plug>(GitGutterNextHunk)

def PreviewHunk(): void
    exec 'GitGutterPreviewHunk'
    silent! wincmd P
enddef
nnoremap <leader>gp <ScriptCmd>PreviewHunk()<CR>

omap ih <Plug>(GitGutterTextObjectInnerPending)
omap ah <Plug>(GitGutterTextObjectOuterPending)
xmap ih <Plug>(GitGutterTextObjectInnerVisual)
xmap ah <Plug>(GitGutterTextObjectOuterVisual)
# }}} keymap #


augroup VcSitePlugGit
    au!
    au FileType diff nnoremap gq <Cmd>close<CR>
augroup END
