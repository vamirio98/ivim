vim9script

var msgQueue = []

export def Notify(what: any, color: string = null_string,
        keep: bool = false): void
    var msg: string = type(what) == v:t_string ? what :
        (type(what) == v:t_list ? join(what, '\n') : string(what))
    if !v:vim_did_enter
        msgQueue += [function(Notify, [msg, color, keep])]
        return
    endif

    redraw
    exec $'echohl {color}'
    exec $'echo{keep ? 'm' : ''} ''{msg}'''
    echohl None
enddef

export def Error(what: any, keep: bool = true)
    Notify(what, 'ErrorMsg', keep)
enddef

export def Warn(what: any, keep: bool = true)
    Notify(what, 'WarningMsg', keep)
enddef

export def Info(what: any, keep: bool = false)
    Notify(what, 'Identifier', keep)
enddef

augroup VcAutoloadUtilNotify
    au!
    au VimEnter * for Msg in msgQueue | Msg() | endfor | msgQueue = []
augroup END
