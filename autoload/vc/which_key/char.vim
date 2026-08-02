vim9script

export def IsTerm(c: string): bool
    return c == "\<C-c>" || c == "\<esc>"
enddef
