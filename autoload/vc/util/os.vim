vim9script

import autoload './string.vim' as str


var systemUname: string = null_string
const windows: bool = has('win32') || has('win64')


# Distinguish OS {{{ #

# uname -a
export def Uname(force: bool = false): string
    if systemUname != null && !force
        return systemUname
    endif

    var uname: string
    if windows
        uname = system('cmd.exe /c ver')->str.Strip()
    else
        uname = system('uname -a')->str.Strip()
    endif
    systemUname = uname
    return systemUname
enddef


export def IsWin(): bool
    return windows
enddef

var hasDetectWsl: bool = false
var wsl: bool = false
export def IsWsl(force: bool = false): bool
    if hasDetectWsl && !force
        return wsl
    endif
    hasDetectWsl = true

    if windows
        wsl = false
        return wsl
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
            if t->str.Contains('Microsoft')
                wsl = true
                return wsl
            endif
        endfor
    endif

    if $WSL_DISTRO_NAME != ''
        wsl = true
        return wsl
    endif

    if Uname()->str.Contains('Microsoft')
        wsl = true
        return wsl
    endif

    wsl = false
    return wsl
enddef


export def IsUnix(): bool
    return !IsWin() && !IsWsl()
enddef
# }}} Distinguish OS #


# Change dir {{{ #
export def GetCd(): string
    return haslocaldir() ? (haslocaldir() == 1 ? 'lcd' : 'tcd') : 'cd'
enddef


export def Chdir(p: string): void
    silent exec $'{GetCd()} {fnameescape(p)}'
enddef


export def ChdirNoAutocmd(p: string): void
    noautocmd Chdir(p)
enddef
# }}} Change dir #

# Temporary path {{{ #
export def TmpFile(): string
    return tempname()
enddef


export def TmpDir(): string
    return tempname()->fnamemodify(':h')
enddef
# }}} Temporary path #
