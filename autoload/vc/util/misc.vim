vim9script

import autoload './os.vim'
import autoload './path.vim'

var windows: bool = os.IsWin()

#----------------------------------------------------------------------
# find files in $PATH
#----------------------------------------------------------------------
export def Which(name: string): string
    var sep: string = windows ? ';' : ':'
    if path.IsAbs(name) && path.IsFile(name)
        return name
    endif
    var ext: list<string> = ['']  # for the filename without externsion
    if windows
        ext = ext + ['.exe', '.cmd', '.bat', 'vbs']
    endif
    for p in split($PATH, sep)
        for fext in ext
            var fpath: string = path.Join(p, name) .. fext
            if path.IsFile(fpath)
                return path.Abspath(fpath)
            endif
        endfor
    endfor
    return null_string
enddef


#----------------------------------------------------------------------
# check whether {name} is executable
#----------------------------------------------------------------------
export def Executable(name: string): string
    return !Which(name)->empty()
enddef
