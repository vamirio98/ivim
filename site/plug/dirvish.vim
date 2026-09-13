vim9script

import autoload 'util/msg.vim' as mMsg


g:vcDirvishHideDotfile = get(g:, 'vcDirvishHideDotfile', 1)

# sort and hide files, then locate related file
def SetupDirvish()
    # NOTE: because vim only remember location of a buffer when leave it,
    # if the buffer content changed, the cursor will stay in another file
    # when reenter the same buffer. e.g., toggle hide dot-file or files in
    # a directory have changed
    b:vcDirvishCurFile = get(b:, 'vcDirvishCurFile', getline('.'))
    if g:vcDirvishHideDotfile
        exec 'silent! keeppatterns g@\v[\/]\.[^\/]+[\/]?$@d _'
        # add current file again if it's dotfile
        if match(b:vcDirvishCurFile, '\v[\/]\.[^\/]+[\/]?$') >= 0
            setline(line('$') + 1, b:vcDirvishCurFile)
        endif
    endif
    # sort filename
    exec 'sort ,^.*[\/],'
    var vcDirvishCurFile: string = escape(b:vcDirvishCurFile, '.*[]~\')
    # locate to current file
    search(vcDirvishCurFile, 'wc')

    nnoremap <silent><buffer> gh <ScriptCmd>ToggleHideDotfile()<CR>
enddef

def ToggleHideDotfile()
    g:vcDirvishHideDotfile = !g:vcDirvishHideDotfile
    mMsg.Info(printf('%s dot files', g:vcDirvishHideDotfile ? 'Hide' : 'Show'))
    exec 'Dirvish'
enddef

augroup vc_site_plug_dirvish
    au!
    au FileType dirvish SetupDirvish()
    au BufLeave * if &ft ==# 'dirvish' && exists('b:vcDirvishCurFile')
        | unlet b:vcDirvishCurFile | endif
augroup END
