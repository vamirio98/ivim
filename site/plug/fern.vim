vim9script
nnoremap <space>fb <cmd>Fern . -reveal=% -drawer -toggle<cr>

def SetupMapping(): void
    nnoremap <buffer> q <cmd>q<cr>
    nmap <buffer> r <Plug>(fern-action-reload)
enddef

augroup VcSitePlugFern
    au!
    au FileType fern SetupMapping()
augroup END
