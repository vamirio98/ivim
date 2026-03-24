vim9script

import autoload './string.vim' as str

#---------------------------------------------------------------
# safe input
#---------------------------------------------------------------
export def Input(...args: list<any>): string
    var text: string = null_string
    inputsave()
    try
        text = call('input', args)
    catch /^Vim:Interrupt$/
        text = null_string
    endtry
    inputrestore()
    return str.Strip(text)
enddef


#----------------------------------------------------------------
# safe confirm, the index is start from 1
#----------------------------------------------------------------
export def Confirm(...args: list<any>): number
    var choice: number = 0
    inputsave()
    try
        choice = call('confirm', args)
    catch /^Vim:Interrupt$/
        choice = 0
    endtry
    inputrestore()
    return choice
enddef


#----------------------------------------------------------------------
# safe inputlist, the index is start from 1
#----------------------------------------------------------------------
export def Inputlist(textlist: list<string>): number
    var choice: number = 0
    inputsave()
    try
        choice = inputlist(textlist)
    catch /^Vim:Interrupt$/
        choice = 0
    endtry
    inputrestore()
    return choice
enddef


#---------------------------------------------------------------
# getchar, also deal with <C-c>, return the key code
#---------------------------------------------------------------
export def Getchar(wait: bool = true): string
    var code: any = null
    try
        if wait
            code = getchar()
        else
            code = getchar(0)
        endif
    catch /^Vim:Interrupt$/
        code = "\<C-c>"
    endtry

    if type(code) == v:t_number && code == 0  # no code available with no wait
        # avoid unused call for this function, e.g., call it continuously
        # even if there are no input event
        try
            exec "sleep 15m"
        catch /^Vim:Interrupt$/
            code = "\<C-c>"
        endtry
    endif

    var ch: string = type(code) == v:t_number ? nr2char(code) : code
    return ch
enddef
