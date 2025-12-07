vim9script

import autoload './notify.vim'

export def Stacktrace(): string
    # skip this function and its caller
    return expand('<stack>')->split('\.\.')[: -3]
        ->map((_, v) => v->substitute('^function ', '', ''))
        ->join(' -> ')->escape('\')
enddef

def FormatErrMsg(errMsg: string): string
    return errMsg == null ? '' : ' => ' .. errMsg
enddef

export def Assert(cond: bool, errMsg: string = null_string): bool
    if cond
        return true
    endif
    notify.Error($'error: {Stacktrace()}{FormatErrMsg(errMsg)}')
    return false
enddef

export def Equal(actual: any, expected: any, errMsg: string = null_string): bool
    if actual == expected
        return true
    endif
    notify.Error($'error: {Stacktrace()} [{string(actual)} != {string(expected)}]{FormatErrMsg(errMsg)}')
    return false
enddef

export def NotEqual(actual: any, expected: any, errMsg: string = null_string): bool
    if actual != expected
        return true
    endif
    notify.Error($'error: {Stacktrace()} [{string(actual)} == {string(expected)}]{FormatErrMsg(errMsg)}')
    return false
enddef
