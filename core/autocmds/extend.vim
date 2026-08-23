vim9script

# depend on vc itself

import autoload 'util/msg.vim' as mMsg


# auto load change.
set autoread
augroup VcCoreAutocmdsExtendAutoRead
    au!
    # trigger autoread when cursor stop moving, buffer change or terminal focus
    au CursorHold,CursorHoldI,BufEnter,FocusGained *
                \ if mode() !~ '\v(c|r.?|!|t)' && getcmdwintype() == ''
                \ | checktime | endif
    # notification after file change
    au FileChangedShellPost *
                \ mMsg.Warn('File changed on disk. Buffer reloaded.')
augroup END


# resize splits if window got resized
def ResizeSplits(): void
    var curTab: number = tabpagenr()
    tabdo wincmd =
    exec $'tabnext {curTab}'
enddef
augroup VcCoreAutocmdsExtendResizeSplits
    au!
    au VimResized * ResizeSplits()
augroup END


# go to last loc when opening a buffer
augroup VcCoreAutocmdsExtendLastLoc
    au!
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
                \ && &filetype != "gitcommit"
                | execute("normal `\"")
                | endif
augroup END


# wrap and check for spell in text filetypes
augroup VcCoreAutocmdsExtendWrapSpell
    au!
    au FileType text,gitcommit,markdown,plaintex,typst
                \ setlocal nowrap | setlocal spell
augroup END


# fix conceallevel for json files
augroup VcCoreAutocmdsExtendJsonConceal
    au!
    au FileType json,jsonc,json5 setlocal conceallevel=0
augroup END


# auto create dir when saving a file, in case some intermediate
# directory does not exist
def Mkdirp(): void
    var fn: string = expand('%:p')
    # avoid specific file like fugitive
    if match(fn, '^\w\w+:[\\/][\\/]') != -1
        return
    endif
    var d: string = fnameescape(fnamemodify(fn, ':h'))
    if !isdirectory(d)
        if exists('*mkdir')
            mkdir(d, 'p')
        else
            mMsg.Warn('no mkdir()')
        endif
    endif
enddef
augroup VcCoreAutocmdsExtendAutoCreateDir
    au!
    au BufWritePre * Mkdirp()
augroup END


# close some filetypes with <q>
def Clear(): void
    var bnr: number = bufnr('%')
    close
    exec $'bwipeout! {bnr}'
enddef
def ClearWithQ(): void
  setlocal nobuflisted
  nnoremap <buffer> q <ScriptCmd>call Clear()<cr>
enddef

augroup VcCoreAutocmdsExtendClearWithQ
    au!
    # do NOT add any space between two filetype
    au FileType help,qf,PlenaryTestPopup,checkhealth,dbout,gitsigns-blame,
                \grug-far,lspinfo,neotest-output,neotest-output-panel,
                \neotest-summary,notify,spectre_panel,startuptime,tsplayground
                \ ClearWithQ()
augroup END


# make it easier to close man-files when opened inline
augroup VcCoreAutocmdsExtendManUnlisted
    au!
    au FileType man setlocal nobuflisted
augroup END
