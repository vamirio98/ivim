vim9script


export def Close(target: number = bufnr('%')): void
    if !bufexists(target)
        return
    endif

    if getbufvar(target, '&modified')
        var choice: number = confirm($'Save changes to {bufname(target)}',
            "&Yes\n&No\n&Cancel")
        if choice == 3  # cancel
            return
        elseif choice == 1  # yes
            var bnr = bufnr('%')
            noautocmd exec $'buffer {target} | update | buffer {bnr}'
        endif
    endif

    var curWin: number = winnr()
    defer () => {
        noautocmd exec $':{curWin}wincmd w'
    }()

    # if any window showing the aiming buffer, change to another buffer
    var wins: list<number> = range(1, winnr('$'))
        ->filter($'winbufnr(v:val) == {target}')
    for w in wins
        # locate to the aim window
        noautocmd exec $':{w}wincmd w'

        # try using alternate buffer or previous buffer
        var alt: number = bufnr('#')
        if alt > 0 && buflisted(alt) && alt != target
            exec 'buffer' alt
        else
            try
                bprevious
            catch /E85: There is no listed buffer/
                exec 'enew'
            endtry
        endif

        # no other buffer in buffer list
        if bufnr('%') == target
            exec 'enew'
        endif
    endfor

    exec 'bdelete!' target
enddef


export def CloseOthers(): void
    var curBuf: number = bufnr('%')
    for bufline in execute('ls')->split('\n')
        var bnr: number = bufline->split(' ')[0]->str2nr()
        if bnr != curBuf
            Close(bnr)
        endif
    endfor
enddef
