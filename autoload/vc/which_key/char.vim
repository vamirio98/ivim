vim9script

export def IsCancel(c: string): bool
    return c == "\<C-c>" || c == "\<esc>"
enddef
