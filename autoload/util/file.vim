vim9script

import autoload './path.vim' as mPath

type Path = mPath.Path


# only update the file if the handle succeed
#
# {handle}: called as handle(tmpFile)
export def SafeHandle(a_fpath: string, A_handle: func(string): void): string
    var tmpFile: string = $'{a_fpath}.{getpid()}.vc~'
    try
        A_handle(tmpFile)
        if !mPath.IsFile(tmpFile)
            return $'error: no {tmpFile} found'
        endif
        rename(tmpFile, a_fpath)
    catch
        return string(v:exception)
    finally
        delete(tmpFile)
    endtry

    return ''
enddef
