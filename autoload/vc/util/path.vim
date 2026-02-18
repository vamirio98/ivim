vim9script

import autoload "./os.vim"

const windows: bool = os.IsWin()
export const sep: string = (windows && !&shellslash) ? '\' : '/'
export const sepPattern: string = (windows && !&shellslash) ? '\v(\/|\\)' : '/'


export def IsPath(path: string): bool
    return path =~ '\v((^(\/|\\|(\a:[\/\\])))|(^(\.{1,2})[\/\\])|(^(\.{1,2})$))'
enddef

export def IsDir(path: string): bool
    return isdirectory(path)
enddef

export def IsFile(path: string): bool
    return filereadable(path) || (!glob(path, 1)->empty() && !isdirectory(path))
enddef


# return the name of entry
export def ListDir(dir: string): list<string>
    return readdir(dir)
enddef


export def Abspath(path: string): string
    var p: string = path
    if p =~ "'."
        try
            var m: string = execute($"silent exec ':marks' {p[1]}")
            p = m->split('\n')[-1]->split()[-1]
            p = filereadable(p) ? p : null_string
        catch
            p = '%'
        endtry
    endif

    if p == '%'
        p = expand('%')
        if &bt == 'terminal'
            p = null_string
        elseif &bt != ''
            var isDir: bool = false
            if p =~ '\v^fugitive\:[\\\/]{3}'
                return Abspath(p)
            elseif p =~ '[\/\\]$'
                if p =~ '^[\/\\]' || p =~ '\v^\a:[\/\\]'
                    isDir = isdirectory(p)
                endif
            endif
            p = isDir ? p : null_string
        endif
    elseif p =~ '\v^\~[\/\\]?'
        p = expand(p)
    elseif p =~ '\v^fugitive\:[\\\/]{3}'
        p = strpart(p, windows ? 12 : 11)
        var pos: number = stridx(p, '.git')
        if pos >= 0
            p = strpart(p, 0, pos)
        endif
        p = fnamemodify(p, ':h')
    endif
    p = fnamemodify(p, ':p')
    p = substitute(p, '\v[\/\\]+', (windows ? '\\' : '/'), 'g')
    if p =~ '[\/\\]$'
        p = fnamemodify(p, ':h')
    endif
    return p
enddef


#----------------------------------------------------------------------
# check absolute path name
#----------------------------------------------------------------------
export def IsAbs(path: string): bool
    if path->empty()
        return false
    endif
    if path[0] == '~'
        return true
    endif
    if windows
        if path =~ '\v^\a:[\/\\]' | return true | endif
        if path[0] == '\' | return true | endif
        return false
    endif
    return path[0] == '/'
enddef


#----------------------------------------------------------------------
# join two path
#----------------------------------------------------------------------
def JoinTwoPath(home: string, name: string): string
    if empty(home) | return name | endif
    if empty(name) | return home | endif

    if IsAbs(name)
        return name
    endif
    var path: string = null_string
    if path[-1] =~ sepPattern
        path = path .. name
    else
        path = home .. sep .. name
    endif
    path = substitute(path, '\v[\/\\]+', (windows ? '\\' : '/'), 'g')
    return path
enddef


#--------------------------------------------------------------
# python: os.path.join
#--------------------------------------------------------------
export def Join(...paths: list<string>): string
    var ret: string = null_string
    for p in paths
        ret = JoinTwoPath(ret, p)
    endfor
    return ret
enddef


#----------------------------------------------------------------------
# dirname
#----------------------------------------------------------------------
export def Dirname(path: string): string
    return fnamemodify(path, ':h')
enddef


#----------------------------------------------------------------------
# basename of /foo/bar is bar
#----------------------------------------------------------------------
export def Basename(path: string): string
    return fnamemodify(path, ':t')
enddef


#----------------------------------------------------------------------
# Normalize({path} [, {lower}])
# normalize, translate path to unix format absoute path
# {lower} Whether to translate to uppercase to lowercase, useful when
#         on Windows, default: false
#----------------------------------------------------------------------
export def Normalize(path: string, lower: bool = false): string
    if empty(path) | return '' | endif

    var newPath: string = path
    if (!windows && newPath !~ '^/') || (windows && newPath !~ '^\a:[\/\\]')
        newPath = fnamemodify(newPath, ':p')
    endif
    if windows
        newPath = tr(newPath, '\', '/')
    endif
    if lower && (windows || has('win32unix'))
        newPath = tolower(newPath)
    endif
    newPath = substitute(newPath, '\v/+', '/', 'g')
    if newPath =~ '^/$' || (windows && newPath =~ '^\a:/$')
        return newPath
    endif
    if newPath[-1] == '/'
        newPath = fnamemodify(newPath, ':h')
    endif
    return newPath
enddef


#----------------------------------------------------------------------
# normal case, if on Windows and path contains uppercase letter,
# change it to lowercase
#----------------------------------------------------------------------
export def Normcase(path: string): string
    return (windows && !has('win32unix')) ? tolower(path) : path
enddef


export def Equal(path1: string, path2: string): bool
    if path1 == path2
        return true
    endif
    var p1: string = Normcase(Abspath(path1))
    var p2: string = Normcase(Abspath(path2))
    return p1 == p2
enddef


#----------------------------------------------------------------------
# return true if base directory contains child
#----------------------------------------------------------------------
export def Contains(base: string, child: string): bool
    var newBase: string = Abspath(base)->Normalize(true)
    var newChild: string = Abspath(child)->Normalize(true)
    return stridx(newChild, newBase) == 0
enddef


#----------------------------------------------------------------------
# return a relative version of a path
#----------------------------------------------------------------------
export def Relpath(path: string, base: string = null_string): string
    var newPath: string = Abspath(path)->Normalize(true)
    var newBase: string = Abspath(base == null ? '.' : base)->Normalize(true)
    var head: string = null_string
    while true
        if Contains(newBase, newPath)
            var size: number = strlen(newBase) + (newBase =~ '/$' ? 0 : 1)
            var relpath: string = head .. strpart(newPath, size)
            if windows
                relpath = substitute(relpath, '/', '\\', 'g')
            endif
            return relpath == '' ? '.' : relpath
        endif

        var prev: string = newBase
        head = '../' .. head
        newBase = fnamemodify(newBase, ':h')
        if newBase == prev
            break
        endif
    endwhile
    throw $'error: no common part in {path} and {base}'
enddef


#----------------------------------------------------------------------
# python: os.path.split
#----------------------------------------------------------------------
export def Split(path: string): tuple<string, string>
    var p1 = fnamemodify(path, ':h')
    var p2 = fnamemodify(path, ':t')
    return (p1, p2)
enddef


#----------------------------------------------------------------------
# split externsion, return (main, ext)
#----------------------------------------------------------------------
export def SplitExt(path: string): tuple<string, string>
    var dotPos: number = strridx(path, '.')
    if dotPos <= 0
        return (path, null_string)
    endif
    var sepPos: number = strridx(path, sep)
    if sepPos > dotPos || sepPos == dotPos - 1
        return (path, null_string)
    endif
    var main: string = strpart(path, 0, dotPos)
    var ext: string = strpart(path, dotPos + 1)
    return (main, ext)
enddef


#----------------------------------------------------------------------
# strip ending slash
#----------------------------------------------------------------------
export def StripSlash(path: string): string
    if path =~ '\v[\/\\]$'
        return fnamemodify(path, ':h')
    endif
    return path
enddef


#----------------------------------------------------------------------
# exists
#----------------------------------------------------------------------
export def Exists(path: string): bool
    return isdirectory(path) || filereadable(path) || !empty(glob(path, 1))
enddef


#----------------------------------------------------------------------
# Win2Unix({winpath} [, {prefix}])
# {prefix} Path prefix, will be add to `winpath`,
#          default: ''
#----------------------------------------------------------------------
export def Win2Unix(winpath: string, prefix: string = '/'): string
    var p: string = null_string
    if winpath =~ '^\a:[\/\\]'
        var drive: string = tolower(winpath[0])
        var name: string = strpart(winpath, 3)
        name = substitute(name, '\v[\/\\]+', '/', 'g')
        p = Join(prefix, drive, name)
        return substitute(p, '\v[\/\\]+', '/', 'g')
    elseif winpath =~ '^[\/\\]'
        var drive: string = tolower(strpart(getcwd(), 0, 1))
        var name: string = strpart(winpath, 1)
        name = substitute(name, '\v[\/\\]+', '/', 'g')
        p = Join(prefix, drive, name)
        return substitute(p, '\v[\/\\]+', '/', 'g')
    else
        return substitute(winpath, '\v[\/\\]+', '/', 'g')
    endif
enddef


#----------------------------------------------------------------------
# Shorten({path} [, {limit}])
# shorten path
# {limit} The path length limit, default: 40
#----------------------------------------------------------------------
export def Shorten(path: string, limit: number = 40): string
    var home: string = expand('~')
    var newPath: string = path
    var size: number = 0
    if Contains(home, path)
        size = strlen(home)
        newPath = Join('~', strpart(newPath, size + 1))
    endif
    size = strlen(newPath)
    if size > limit
        var t: string = pathshorten(newPath, 2)
        size = strlen(t)
        if size > limit
        return pathshorten(newPath)
        endif
        return t
    endif
    return newPath
enddef


# Testing suit. {{{ #
if 0
    import autoload './debug.vim'

    var Assert = debug.Assert

    def TestIsPath(): bool
        return Assert(IsPath('.')) && Assert(IsPath('..')) &&
            Assert(IsPath('./')) && Assert(IsPath('../')) &&
            Assert(IsPath('./a')) && Assert(IsPath('../a')) &&
            Assert(IsPath('./a/..')) && Assert(IsPath('../a/..')) &&
            Assert(!IsPath('...')) &&
            Assert(IsPath('C:/')) && Assert(IsPath('C:\\')) &&
            Assert(IsPath('C:/a')) && Assert(IsPath('C:\\a')) &&
            Assert(IsPath('C:/a\\..')) && Assert(IsPath('C:\\a/..')) &&
            Assert(IsPath('/tmp')) && Assert(IsPath('/tmp/')) &&
            Assert(IsPath('/tmp/..')) && Assert(IsPath('/tmp\\..')) &&
            Assert(!IsPath('https://')) && Assert(!IsPath(''))
    enddef

    def Test(): void
        TestIsPath()
    enddef

    Test()
endif
# }}} Testing suit. #
