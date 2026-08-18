vim9script

import autoload './str.vim' as str


var s_sysUname: string = null_string
const s_win: bool = has('win32') || has('win64')


# Distinguish OS {{{ #

# uname -a
# Uname([{forceReDetect}])
export def Uname(forceReDetect: bool = false): string
    if s_sysUname != null && !forceReDetect
        return s_sysUname
    endif

    var uname: string
    if s_win
        uname = system('cmd.exe /c ver')->str.Strip()
    else
        uname = system('uname -a')->str.Strip()
    endif
    s_sysUname = uname
    return s_sysUname
enddef


export def IsWin(): bool
    return s_win
enddef


var s_hasDetectWsl: bool = false
var s_wsl: bool = false
export def IsWsl(forceReDetect: bool = false): bool
    if s_hasDetectWsl && !forceReDetect
        return s_wsl
    endif
    s_hasDetectWsl = true

    if s_win
        s_wsl = false
        return s_wsl
    endif

    var ver: string = '/proc/version'
    var text: list<string>
    if filereadable(ver)
        try
            text = readfile(ver, '', 3)
        catch
            text = []
        endtry
        for t in text
            if t->stridx('Microsoft') >= 0
                s_wsl = true
                return s_wsl
            endif
        endfor
    endif

    if $WSL_DISTRO_NAME != ''
        s_wsl = true
        return s_wsl
    endif

    if Uname()->stridx('Microsoft') >= 0
        s_wsl = true
        return s_wsl
    endif

    s_wsl = false
    return s_wsl
enddef


export def IsUnix(): bool
    return !IsWin() && !IsWsl()
enddef
# }}} Distinguish OS #
