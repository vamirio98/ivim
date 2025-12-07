vim9script

import autoload './popup.vim'

#---------------------------------------------------------------
# Open({question} [, {choices} [, {default} [, {title}]]])
# {choices}: e.g.: '&Yes\n&No\n&Cancel' will generate three
#                  choices with hot key:
#                  Yes(Y/y, return 1),
#                  No(N/n, return 2)
#                  and Cancel(C/c, return 3).
#                  If press <Esc> or <C-c>, 0 will return
#---------------------------------------------------------------
export def Open(question: string, choices: string = null_string,
        default: number = 1, title: string = null_string): number
    return default
enddef
