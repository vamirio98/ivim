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
