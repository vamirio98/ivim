vim9script

import autoload './os.vim' as mOs
import autoload './path.vim' as mPath

var windows: bool = mOs.IsWin()

#----------------------------------------------------------------------
# find files in $PATH
#----------------------------------------------------------------------
export def Which(name: string): string
    var sep: string = windows ? ';' : ':'
    if mPath.IsAbsolute(name) && mPath.IsFile(name)
        return name
    endif
    var ext: list<string> = ['']  # for the filename without externsion
    if windows
        ext = ext + ['.exe', '.cmd', '.bat', 'vbs']
    endif
    for p in split($PATH, sep)
        for fext in ext
            var fpath: string = mPath.Joinpath(p, name) .. fext
            if mPath.IsFile(fpath)
                return mPath.Resolve(fpath)
            endif
        endfor
    endfor
    return null_string
enddef


#----------------------------------------------------------------------
# check whether {name} is executable
#----------------------------------------------------------------------
export def Executable(name: string): bool
    return !Which(name)->empty()
enddef
