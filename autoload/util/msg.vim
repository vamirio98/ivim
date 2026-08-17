vim9script

var msgQueue = []

export def Msg(what: any, color: string = null_string,
        keep: bool = false): void
    var msg: string = type(what) == v:t_string ? what :
        (type(what) == v:t_list ? join(what, '\n') : string(what))
    if !v:vim_did_enter
        msgQueue += [function(Msg, [msg, color, keep])]
        return
    endif

    redraw
    exec $'echohl {color}'
    exec $'echo{keep ? 'm' : ''} ''{msg->substitute("'", "''", 'g')}'''
    echohl None
enddef

export def Error(what: any, keep: bool = true)
    Msg(what, 'ErrorMsg', keep)
enddef

export def Warn(what: any, keep: bool = true)
    Msg(what, 'WarningMsg', keep)
enddef

export def Info(what: any, keep: bool = false)
    Msg(what, 'Identifier', keep)
enddef


export def Clear(): void
    :message clear
enddef


augroup VcAutoloadUtilMsg
    au!
    au VimEnter * for F in msgQueue | F() | endfor | msgQueue = []
augroup END
