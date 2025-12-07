vim9script

import autoload '../util/interact.vim'

export def BufDel(bTarget: number = bufnr('%')): void
    if &modified
        var choice: number = interact.Confirm(printf('Save changes to %s',
        bufname(bTarget)), "&Yes\n&No\n&Cancel")
        if choice == 0 || choice == 3 # 0 for <Esc>/<C-c> and 3 for Cancel
            return
        endif
        if choice == 1 # Yes
            update
        endif
    endif

    var wins: list<number> = filter(range(1, winnr('$')),
        'winbufnr(v:val) == ' .. bTarget)
    var curWin: number = winnr()
    for w in wins
        # locate to the aim window
        exec $':{w}wincmd w'
        # try using alternate buffer or previous buffer
        var alt: number = bufnr('#')
        if alt > 0 && buflisted(alt) && alt != bTarget
            exec 'buffer' alt
        else
            try
                bprevious
            catch /E85: There is no listed buffer/
                # do nothing
            endtry
        endif

        if bTarget == bufnr('%')
            # numbers of listed buffers which are not the target to be deleted
            var bListed: list<number> = range(1, bufnr('$'))->filter(
                $'buflisted(v:val) && v:val != {bTarget}'
            )
            # listed, not target and not displayed
            var bHidden: list<number> = copy(bListed)->filter(
                'bufwinnr(v:val) < 0'
            )
            # take the first buffer, if any (could be more intelligent)
            var bjump: number = (bHidden + bListed + [-1])[0]
            if bjump > 0
                exec 'buffer' bjump
            else
                exec 'enew'
            endif
        endif
    endfor

    exec 'bdelete!' bTarget
    exec $':{curWin}wincmd w'
enddef

export def BufDelOther(): void
    var bufs: string = execute('ls')
    var curBuf: number = bufnr('%')
    for bufline in split(bufs, '\n')
        var buf: number = split(bufline, ' ')[0]->str2nr()
        if buf != curBuf
            BufDel(buf)
        endif
    endfor
enddef
