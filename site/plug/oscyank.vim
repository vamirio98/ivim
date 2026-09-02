vim9script

g:oscyank_silent = 1

if !has('clipboard_working')
    # In the event that the clipboard isn't working, it's quit likely taht
    # the + and * registers will not be distinct from the unnamed register.
    # In this case, a:event.regname will always be '' (empty string). However,
    # it can be the case that `has('clipboard_working')` is false, yet `+` is
    # still distinct, so we want to check them all.
    var s_vimOscYankPostRegisters: list<string> = [ '', '+', '*' ]
    # copy text to clipboard on both (y)ank and (d)elete
    var s_vimOscYankOperators = [ 'y', 'd' ]

    def VimOscYankPostCallback(event: any): void
        if index(s_vimOscYankPostRegisters, event.regname) != -1
                && index(s_vimOscYankOperators, event.operator) != -1
            g:OSCYankRegister(event.regname)
        endif
    enddef

    augroup VcSitePlugOscYankPost
        au!
        au TextYankPost * VimOscYankPostCallback(v:event)
    augroup END
endif
