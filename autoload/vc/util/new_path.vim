vim9script

import autoload "./os.vim"
import autoload "./string.vim" as ms

const windows: bool = os.IsWin()
export const sep: string = (windows && !&shellslash) ? '\' : '/'
export const sepPat: string = (windows && !&shellslash) ? '\v(\/|\\)' : '/'


# legal path format:
# Windows:  c:\a, .\, ..\
# Posix:    /, /a, ./, ../
# UNC:      \\192.168.1.1\share\, //192.168.1.1/share/
# Protocol: ftp://


# AsPosix({path} [, {lower}])
# convert a path to posix style
# {lower}: if ture and the system is Window or wsl,
# convert all upper case to lower
export def AsPosix(a_path: string, lower: bool = false): string
    if empty(a_path) | return '' | endif
    var path: string = ''
    # start with '//' maybe a protocol, start with more than two '/'
    # should be treat as '/'. See The Open Group Base Specifications Issue 6,
    # paragraph 4.11 Pathname Resolution
    # https://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap04.html#tag_04_11
    if a_path =~ '\v^//([^/]|$)' || a_path =~ '\v^\\\\([^\\]|$)'  # UNC
        path = a_path->slice(0, 2)->tr('\', '/') ..
            a_path[2 :]->ms.Replace('\', '/')->ms.Replace('\v/+', '/')
    elseif a_path =~ '\v[^/:]{2,}(://)[^/]+'  # e.g., ftp://x
        var pos = a_path->stridx('://') + 3
        path = a_path->slice(0, pos) ..
            a_path[pos :]->ms.Replace('\', '/')->ms.Replace('\v/+', '/')
    else
        path = a_path->ms.Replace('\', '/')->ms.Replace('\v/+', '/')
    endif
    # if not absolute path, assume that it is in current directory
    if path !~ '\v^(/|\.|(\a+:))'
        path = './' .. path
    endif
    if lower && (windows || has('win32unix'))
        path = tolower(path)
    endif
    return path
enddef


class Path
    var path: string = null_string  # raw as user input
    var posix: string = null_string  # store as posix style

    def new(a_path: any = null)
        if a_path == null
            return
        endif

        if a_path->type() == v:t_string
            this.path = a_path
        elseif a_path->instanceof(Path)
            this.path = a_path.path
        else
            throw $'only support string or Path'
        endif

        this.posix = this.path->AsPosix()
    enddef

    def empty(): bool
        return this.path->empty()
    enddef

    def string(): string
        return this.path
    enddef


    def IsUnc(): bool
        return this.posix =~ '\v^//[^/]+'
    enddef

    def IsProtocol(): bool
        return this.posix =~ '\v^[^/:]{2,}(://)[^/]+'
    enddef

    def IsAbsolute(): bool
        return (windows && this.posix =~ '\v^\a:($|(/([^/]|$)))') ||
            (!windows && this.posix =~ '\v(^/([^/]|$))') ||
            this.IsUnc() || this.IsProtocol()
    enddef

    def IsRelative(): bool
        return !this.IsAbsolute()
    enddef

    def IsPath(): bool
        # return this.path =~ '\v((^(\/|\\|(\a:[\/\\])))|(^(\.{1,2})[\/\\])|(^(\.{1,2})$))'
        return this.IsAbsolute() || this.IsRelative() ||
            this.IsUnc() || this.IsProtocol()
    enddef


    # resolve the path, return as posix format
    # NOTE: if the path is a network path, this function may freeze when parsing
    def Resolve(lower: bool = false): Path
        if this.empty() | return Path.new() | endif

        var path: string = null_string
        # network path, may freeze terminal when parsing
        if this.IsUnc() || this.IsProtocol()
            path = this.posix->fnamemodify(':p')->AsPosix(lower)
            if path->len() != 2
                path = path[: -2]
            endif
        elseif this.IsProtocol()
            path = this.posix->fnamemodify(':p')->AsPosix(lower)
            if path !~ '\v://$'
                path = path[: -2]
            endif
        else
            path = this.posix->fnamemodify(':p')->AsPosix(lower)
            if path[-1] == '/' &&
                    path->len() != 1 &&
                    !(windows && path =~ '^\a:/$')
                path = path[: -2]
            endif
        endif

        return Path.new(path)
    enddef

    def Exists(): bool
        return !this.posix->glob(1)->empty()
    enddef

    def IsDir(): bool
        return isdirectory(this.posix)
    enddef

    def IsFile(): bool
        return filereadable(this.posix) ||
            (!this.posix->glob(1)->empty() && !isdirectory(this.posix))
    enddef


    def _JoinTwoPath(a: Path, b: Path, checkAbs: bool = true): Path
        if a->empty() | return b | endif
        if b->empty() | return a | endif

        if checkAbs && b.IsAbsolute()
            return Path.new(b)
        endif

        var path: string = a.posix
        # `b` must not start with '/' if !`ignoreAbs`
        if path[-1] != '/' && (!checkAbs && b.posix !~ '\v^/')
            path ..= '/'
        endif
        return Path.new(path .. b.posix)
    enddef


    def Drive(): Path
        if this.IsUnc()
            # //server
            var sep1 = this.posix->stridx('/', 2)
            if sep1 < 0
                return Path.new(this.posix)
            endif
            var sep2 = this.posix->stridx('/', sep1 + 1)
            # //server/share
            if sep2 < 0
                return Path.new(this.posix)
            endif
            # //server/share/a
            return Path.new(this.posix[0 : sep2 - 1])
        elseif this.posix =~ '\v^\a:'
            return Path.new(this.posix->slice(0, 2))
        else  # protocol or posix
            return Path.new()
        endif
    enddef


    def Root(): Path
        if this.IsUnc()
            return Path.new('/')
        elseif this.posix =~ '\v^\a:/'
            return Path.new('/')
        elseif this.posix =~ '\v^/([^/]|$)'
            return Path.new('/')
        else
            return Path.new()
        endif
    enddef


    def Anchor(): Path
        if this.IsProtocol()
            return Path.new()
        else
            return this._JoinTwoPath(this.Drive(), this.Root(), 0)
        endif
    enddef


    def Parts(): list<string>
        if this.IsProtocol()
            return this.posix->split('/', 0)->filter((_, v) => !v->empty())
        endif
        var anchor: string = this.Anchor().posix
        return [anchor] + this.posix[anchor->len() :]->split('/', 0)
    enddef

    # NOTE: this just the string opeartation, so:
    # Path('foo/..').Parent() == Path('foo')
    def Parent(): Path
        var anchor: Path = this.Anchor()
        var anchorLen: number = anchor.posix->len()
        var pos: number = this.posix[anchorLen :]->strridx('/')
        if pos < 0
            if !anchor->empty()
                return anchor
            else
                return Path.new('.')
            endif
        else
            return Path.new(this.posix->slice(0, anchorLen + pos))
        endif
    enddef

    def Parents(): list<Path>
        var p = this.Parent()
        var pp = p.Parent()
        var parents: list<Path> = [ p ]
        while p.posix != pp.posix
            p = pp
            pp = p.Parent()
            parents->add(p)
        endwhile
        return parents
    enddef

    def Samefile(other: Path): bool
        return this.Resolve().path == other.Resolve().path
    enddef

endclass


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
export def ReadDir(dir: string): list<string>
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
    if path[-1] =~ sepPat
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
if 1
    import autoload './debug.vim'

    var Assert = debug.Assert
    var MdEqual = debug.Equal

    var Pn = Path.new

    def TestAsPosix(): bool
        return MdEqual(AsPosix('c:\a\b'), 'c:/a/b') &&
            MdEqual(AsPosix('c:\\a\\\\b'), 'c:/a/b') &&
            MdEqual(AsPosix('////////'), '/') &&
            MdEqual(AsPosix('/a/'), '/a/') && MdEqual(AsPosix('./'), './') &&
            MdEqual(AsPosix('../'), '../') &&
            MdEqual(AsPosix('///a////'), '/a/') &&
            MdEqual(AsPosix('.//'), './') &&
            MdEqual(AsPosix('..///'), '../') &&
            MdEqual(AsPosix('\\a\\\b'), '//a/b') &&
            MdEqual(AsPosix('\\192.168.1.1/a'), '//192.168.1.1/a') &&
            MdEqual(AsPosix('//a/b/'), '//a/b/') &&
            MdEqual(AsPosix('//a////b'), '//a/b') &&
            MdEqual(AsPosix('ftp://a'), 'ftp://a') &&
            MdEqual(AsPosix('http://a//'), 'http://a/') &&
            MdEqual(AsPosix('//'), '//')
    enddef

    def TestPathType(): bool
        return Path.new('\\a\b').IsUnc()->Assert() &&
            (!Path.new('\a\b').IsUnc())->Assert() &&
            Path.new('ab://abc////').IsProtocol()->Assert() &&
            (!Path.new('ab:://ab').IsProtocol())->Assert() &&
            (windows && !Path.new('/a').IsAbsolute())->Assert() &&
            (windows || Path.new('/a').IsAbsolute())->Assert() &&
            Path.new('a:/b').IsAbsolute()->Assert() &&
            Path.new('a:').IsAbsolute()->Assert() &&
            Path.new('a://').IsAbsolute()->Assert() &&
            (!Path.new('//').IsAbsolute())->Assert() &&
            Path.new('./').IsRelative()->Assert() &&
            Path.new('../').IsRelative()->Assert() &&
            Path.new('.').IsRelative()->Assert() &&
            Path.new('..').IsRelative()->Assert() &&
            (windows && Path.new('/a').IsRelative())->Assert() &&
            (windows || !Path.new('/a').IsRelative())->Assert()
    enddef

    def TestResolve(): bool
        if windows
            return Path.new('/a/b///').Resolve()->string()
                ->MdEqual('/a/b'->fnamemodify(':p')->tr('\', '/'))
        else
            return true
        endif
    enddef

    def TestParts(): bool
        return Path.new('//server').Drive()->string()->MdEqual('//server') &&
            Path.new('//server/share').Drive()->string()->MdEqual('//server/share') &&
            Path.new('//server/share/a').Drive()->string()->MdEqual('//server/share') &&
            Pn('ftp://a').Drive()->string()->MdEqual('') &&
            Pn('c:/a/').Root()->string()->MdEqual('/') &&
            Pn('c:a').Root()->string()->MdEqual('') &&
            Pn('/').Root()->string()->MdEqual('/') &&
            Pn('ftp://a').Root()->string()->MdEqual('') &&
            Pn('c:/a/b').Anchor()->string()->MdEqual('c:/') &&
            Pn('c:a/b').Anchor()->string()->MdEqual('c:') &&
            Pn('/etc').Anchor()->string()->MdEqual('/') &&
            Pn('.').Anchor()->empty()->Assert() &&
            Pn('..').Anchor()->empty()->Assert() &&
            Pn().Anchor()->empty()->Assert() &&
            Pn('\\host/share').Anchor()->string()->MdEqual('//host/share/') &&
            Pn('ftp://a').Anchor()->string()->MdEqual('') &&
            Pn('/usr/bin/python3').Parts()->MdEqual(['/', 'usr', 'bin', 'python3']) &&
            Pn('c:\\Program Files/PSF').Parts()->MdEqual(['c:/', 'Program Files', 'PSF']) &&
            Pn('ftp://a').Parts()->MdEqual(['ftp:', 'a']) &&
            Pn('/a/b/c/d').Parent()->string()->MdEqual('/a/b/c') &&
            Pn('/').Parent()->string()->MdEqual('/') &&
            Pn('.').Parent()->string()->MdEqual('.') &&
            Pn('').Parent()->string()->MdEqual('.') &&
            Pn('c:/foo/bar/setup.py').Parents()->copy()
            ->map((_, v) => v->string())->MdEqual([
                'c:/foo/bar', 'c:/foo', 'c:/'
            ]) &&
            Pn('/a/b/c').Parents()->copy()->map((_, v) => v->string())
            ->MdEqual(['/a/b', '/a', '/'])
    enddef

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
        TestIsPath() &&
            TestAsPosix() &&
            TestPathType() &&
            TestResolve() &&
            TestParts()
    enddef

    Test()
endif
# }}} Testing suit. #
