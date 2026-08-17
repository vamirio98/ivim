vim9script

# UNC:      \\192.168.1.1\share\, //192.168.1.1/share/
# Protocol: ftp://

# NOTE: any function no export just handle '/', no '\'
def DoIsUnc(a_path: string): bool
    return a_path =~ '\v^//[^/]+'
enddef

def DoIsProtocol(a_path: string): bool
    return a_path =~ '\v^[^/:]{2,}(://)'
enddef


export def IsUnc(a_path: string): bool
    var path = a_path->tr('\', '/')
    return DoIsUnc(path)
enddef

export def IsProtocol(a_path: string): bool
    var path = a_path->tr('\', '/')
    return DoIsProtocol(path)
enddef


def DoAsPosixUnc(a_path: string): string
    var path: string = a_path->slice(0, 2) ..
        a_path[2 :]->mStr.Replace('\v/+', '/')
    return path
enddef

def DoAsPosixProtocol(a_path: string): string
    var pos = a_path->stridx('://') + 3
    var path = a_path->slice(0, pos) ..
        a_path[pos :]->mStr.Replace('\v/+', '/')
    return path
enddef
