vim9script

import autoload './os.vim' as mOs
import autoload './str.vim' as mStr

const s_win: bool = mOs.IsWin()

export def Sep(): string
    return (s_win && !&shellslash) ? '\' : '/'
enddef

export def SepPat(): string
    return (s_win && !&shellslash) ? '\v(\/|\\)' : '/'
enddef


# legal path format, only Windows and Posix are supported:
# Windows:  c:\a, .\, ..\
# Posix:    /, /a, ./, ../


# NOTE: all UN exported function use '/' as sep
# NOTE: all exported function should call AsNative() before return
def AsNative(a_path: string): string
    return (s_win && !&shellslash) ? a_path->tr('/', '\') : a_path
enddef


# NOTE: any function no export just handle '/', no '\'
def DoIsWin(a_path: string): bool
    return a_path =~ '\v^\a:($|(/([^/]|$)))'
enddef

def DoIsPosix(a_path: string): bool
    return a_path =~ '\v^/($|[^/])'
enddef

export def IsWin(a_path: string): bool
    var path = a_path->tr('\', '/')
    return DoIsWin(path)
enddef

export def IsPosix(a_path: string): bool
    var path = a_path->tr('\', '/')
    return DoIsPosix(path)
enddef

def IsRelativeWin(a_path: string): bool
    return a_path->empty() || a_path->stridx(':') < 0
enddef

def IsRelativePosix(a_path: string): bool
    return a_path->empty() || a_path[0] != '/'
enddef

export def IsRelative(a_path: string): bool
    return s_win ? IsRelativeWin(a_path) : IsRelativePosix(a_path)
enddef

export def IsAbsolute(a_path: string): bool
    return !IsRelative(a_path)
enddef


# remove redundancy '.' and '/'
def DoPrune(a_path: string): string
    var path: string = a_path->mStr.Replace('\v/+', '/')
    # ./
    path = a_path->mStr.Replace('\v(\./)+', './')
    path = path->mStr.Replace('\V/./', '/')

    # trail '/.' or '/'
    if path =~ '\v(/\.)$'
        path = path->slice(0, -1)
    endif
    # c:/ != c:
    if len(path) > 1 && path[-1] == '/' && path !~ '\v:/$'
        path = path->slice(0, -1)
    endif

    return path
enddef


# AsPosix({path} [, {lower}])
# convert a path to posix style
# {lower}: if ture, convert all upper case to lower, useful on Windows
# NOTE:
#   1) if it's not a absolute path, a leading './' will be add
#   2) the trailing './' will be removed except './' which will return '.'
export def AsPosix(a_path: string, lower: bool = false): string
    var path = a_path->tr('\', '/')

    if IsRelative(path) && path !~ '\v^(\.|\.\.)($|/)'
        path = './' .. path
    endif

    path = DoPrune(path)

    return lower ? path->tolower() : path
enddef


export def ExpandPath(a_path: string): string
    var path: string = a_path
    if path =~ "'."
        try
            var m: string = execute($"silent exec ':marks' {path[1]}")
            path = m->split("\n")[-1]->split()[-1]
            path = path->filereadable() ? path : null_string
        catch
            path = '%'
        endtry
    endif

    if path == '%' || path =~ '\v^\~'
        path = path->expand()
    endif

    return path
enddef


export def Home(): string
    return expand('~')
enddef

export def Cwd(): string
    return fnamemodify('.', ':p')
enddef

export def IsPath(a_path: string): bool
    return a_path =~ '\v^\f+$'
enddef

export def IsFile(a_path: string): bool
    return getftype(a_path) == 'file'
enddef

export def IsDir(a_path: string): bool
    return getftype(a_path) == 'dir'
enddef

export def IsSymlink(a_path: string): bool
    return getftype(a_path) == 'link'
enddef

export def IsBlockDevice(a_path: string): bool
    return getftype(a_path) == 'bdev'
enddef

export def IsCharDevice(a_path: string): bool
    return getftype(a_path) == 'cdev'
enddef

export def IsSocket(a_path: string): bool
    return getftype(a_path) == 'socket'
enddef

export def IsFifo(a_path: string): bool
    return getftype(a_path) == 'fifo'
enddef

# return the name of entries
export def Iterdir(a_dir: string): list<string>
    return readdir(a_dir)
enddef


def JoinTwoPath(a_path1: string, a_path2: string): string
    if a_path1->empty()
        return a_path2
    endif
    if a_path2->empty()
        return a_path1
    endif

    if IsAbsolute(a_path2)
        return a_path2
    endif

    var path: string = a_path1 .. '/' .. a_path2
    path = DoPrune(path)

    return path
enddef

export def Joinpath(...paths: list<string>): string
    if paths->empty()
        return ''
    endif

    var path: string = ''
    for p in paths
        path = JoinTwoPath(path, p)
    endfor

    return AsNative(path)
enddef


def DoResolve(a_path: string, lower: bool = false): string
    return a_path->fnamemodify(':p')->AsPosix(lower)
enddef

export def Resolve(a_path: string, lower: bool = false): string
    var path: string = DoResolve(a_path, lower)
    return path->AsNative()
enddef

export def Parent(a_path: string): string
    var path: string = DoResolve(a_path)
    return fnamemodify(path, ':h')->AsNative()
enddef

export def Name(a_path: string): string
    var path: string = DoResolve(a_path)
    return fnamemodify(path, ':t')
enddef


export def IsSamefile(a_path1: string, a_path2: string): bool
    if a_path1 == a_path2
        return true
    endif
    return DoResolve(a_path1, s_win) == DoResolve(a_path2, s_win)
enddef


export def Exists(a_path: string): bool
    return !a_path->glob(1)->empty()
enddef


# NOTE: {other} should be a directory, otherwise will return a wrong result
export def RelativeTo(a_path: string, a_other: string = '.'): string
    var path: string = DoResolve(a_path, s_win)
    var other: string = DoResolve(a_other, s_win)
    var head: string = ''

    while 1
        if path->stridx(other) == 0
            path = path->slice(other->len())
            if path =~ '\v^/'
                path = path->slice(1)
            endif
            return JoinTwoPath(head, path)->AsNative()
        endif

        var newOther: string = fnamemodify(other, ':h')
        if newOther == other
            break
        endif
        other = other = newOther

        head = '../' .. head
    endwhile

    throw $'no common part in ''{a_path}'' and ''{a_other}'''
enddef

export def Mkdir(a_path: string, mode: number = 0o755,
        flags: string = ''): number
    return mkdir(a_path, flags, mode)
enddef

export def Unlink(a_path: string): number
    return delete(a_path)
enddef

export def Rmdir(a_path: string): number
    return delete(a_path, 'd')
enddef


# {limit} The path length limit, default: 40
export def Shortpath(a_path: string, limit: number = 40): string
    var path: string = fnamemodify(a_path, ':~:.')
    if strlen(path) > limit
        path = path->pathshorten(2)
        if strlen(path) > limit
            return path->pathshorten()
        endif
    endif
    return path
enddef


# Temporary path {{{ #
export def TmpFile(): string
    return tempname()
enddef


export def TmpDir(): string
    return tempname()->fnamemodify(':h')
enddef
# }}} Temporary path #


export interface Path
    # these method should be static method, but now vim9script
    # interface do not support static method
    def Home(): Path
    def Cwd(): Path

    def IsAbsolute(): bool
    def IsRelative(): bool

    def AsPosix(lower: bool): string

    def IsFile(): bool
    def IsDir(): bool
    def IsSymlink(): bool
    def IsBlockDevice(): bool
    def IsCharDevice(): bool
    def IsSocket(): bool
    def IsFifo(): bool

    def IterDir(): list<Path>

    def Joinpath(...paths: list<any>): Path

    def Resolve(lower: bool): Path

    def Drive(): Path
    def Root(): Path
    def Anchor: Path

    def Parts(): list<string>
    def Parent(): Path
    def Parents(): list<Path>
    def Name(): string
    def Suffix(): string
    def Suffixes(): list<string>
    def Stem(): string

    def IsSamefile(other: any): bool

    def Exists(): bool

    def RelativeTo(other: any): Path
    def WithName(name: string): Path
    def WithStem(stem: string): Path
    def WithSuffix(suffix: string): Path

    def Mkdir(mode: number, flags: string): number
    def Unlink(): number
    def Rmdir(): number
endinterface


export class PosixPath
    var _raw: string
    var _path: string
    var _ftype: string = null_string

    def string(): string
        return this._raw
    enddef

    def new(a_path: any = '')
        if type(a_path) == v:t_string
            this._raw = a_path->empty() ? '.' : a_path
            this._path = AsPosix(this._raw)
        elseif type(a_path) == v:t_object && a_path->instanceof(Path)
            this._raw = a_path._raw
            this._path = a_path._path
        else
            throw $'invalid param'
        endif
    enddef

    def _newRawPath(a_raw: string, a_path: string)
        this._raw = a_raw
        this._path = a_path
    enddef


    def Home(): Path
        return PosixPath.new(Home())
    enddef

    def Cwd(): Path
        return PosixPath.new(Cwd())
    enddef


    def IsAbsolute(): bool
        return IsAbsolutePosix(this._path)
    enddef

    def IsRelative(): bool
        return IsRelativePosix(this._path)
    enddef


    def AsPosix(lower: bool = false): Path
        return lower ? this._path->tolower() : this._path
    enddef


    def IsFile(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'file'
    enddef

    def IsDir(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'dir'
    enddef

    def IsSymlink(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'link'
    enddef

    def IsBlockDevice(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'bdev'
    enddef

    def IsCharDevice(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'cdev'
    enddef

    def IsSocket(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'socket'
    enddef

    def IsFifo(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'fifo'
    enddef


    def Iterdir(): list<Path>
        if !this.IsDir()
            throw $'not a directory'
        endif
        return readdir(this._path)
            ->map((_, v) => PosixPath.new(this).Joinpath(v))
    enddef


    static def _String(a_path: any): string
        if a_path->type() == v:t_string
            return a_path
        elseif a_path->type() == v:t_object && a_path->instanceof(Path)
            return a_path._path
        else
            throw 'invalid param'
        endif
    enddef


    def Joinpath(...paths: list<any>): Path
        var path: string = this._path
        for p in paths
            var np: string = _String(p)->AsPosix()
            path = JoinTwoPath(path, np)
        endfor
        return PosixPath._newRawPath(path, path)
    enddef


    def Resolve(lower: bool): Path

    def Drive(): Path
    def Root(): Path
    def Anchor: Path

    def Parts(): list<string>
    def Parent(): Path
    def Parents(): list<Path>
    def Name(): string
    def Suffix(): string
    def Suffixes(): list<string>
    def Stem(): string

    def IsSamefile(other: any): bool

    def Exists(): bool

    def RelativeTo(other: any): Path
    def WithName(name: string): Path
    def WithStem(stem: string): Path
    def WithSuffix(suffix: string): Path

    def Mkdir(mode: number, flags: string): number
    def Unlink(): number
    def Rmdir(): number
endclass


export class WinPath
    var _raw: string
    var _path: string
    var _ftype: string = null_string

    def string(): string
        return this._raw
    enddef

    def new(a_path: any = '')
        if type(a_path) == v:t_string
            this._raw = a_path->empty() ? '.' : a_path
            this._path = AsPosix(this._raw)
        elseif type(a_path) == v:t_object && a_path->instanceof(Path)
            this._raw = a_path._raw
            this._path = a_path._path
        else
            throw $'invalid param'
        endif
    enddef

    def _newRawPath(a_raw: string, a_path: string)
        this._raw = a_raw
        this._path = a_path
    enddef


    def Home(): Path
        return WinPath.new(Home())
    enddef

    def Cwd(): Path
        return WinPath.new(Cwd())
    enddef


    def IsAbsolute(): bool
        return IsAbsoluteWin(this._path)
    enddef

    def IsRelative(): bool
        return IsRelativeWin(this._path)
    enddef


    def AsPosix(lower: bool = false): Path
        return lower ? this._path->tolower() : this._path
    enddef


    def IsFile(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'file'
    enddef

    def IsDir(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'dir'
    enddef

    def IsSymlink(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'link'
    enddef

    def IsBlockDevice(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'bdev'
    enddef

    def IsCharDevice(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'cdev'
    enddef

    def IsSocket(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'socket'
    enddef

    def IsFifo(): bool
        if this._ftype == null
            this._ftype = getftype(this._path)
        endif
        return this._ftype == 'fifo'
    enddef


    def Iterdir(): list<Path>
        if !this.IsDir()
            throw $'not a directory'
        endif
        return readdir(this._path)
            ->map((_, v) => WinPath.new(this).Joinpath(v))
    enddef


    def Joinpath(...paths: list<any>): Path
        var path: string = this._path
        for p in paths
            var np: string = _String(p)->AsPosix()
            path = JoinTwoPath(path, np)
        endfor
        return WinPath._newRawPath(path->AsNative(), path)
    enddef


    def Resolve(lower: bool): Path

    def Drive(): Path
    def Root(): Path
    def Anchor: Path

    def Parts(): list<string>
    def Parent(): Path
    def Parents(): list<Path>
    def Name(): string
    def Suffix(): string
    def Suffixes(): list<string>
    def Stem(): string

    def IsSamefile(other: any): bool

    def Exists(): bool

    def RelativeTo(other: any): Path
    def WithName(name: string): Path
    def WithStem(stem: string): Path
    def WithSuffix(suffix: string): Path

    def Mkdir(mode: number, flags: string): number
    def Unlink(): number
    def Rmdir(): number
endclass

export class Path
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
        elseif this.posix =~ '\v^\a:/' || this.IsUnc()
            return Path.new(this.Drive().posix .. '/')
        else
            return this._JoinTwoPath(this.Drive(), this.Root())
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

    def Name(): string
        var anchorLen: number = this.Anchor().posix->len()
        var pos = this.posix[anchorLen :]->strridx('/')
        return this.posix[anchorLen :][pos < 0 ? 0 : pos + 1 :]
    enddef

    def Suffix(): string
        var name: string = this.Name()
        var pos = name->strridx('.')
        return (pos < 0 || pos == 0) ? '' : name[pos :]
    enddef

    def Suffixes(): list<string>
        var name: string = this.Name()
        var pos = name->stridx('.', 1)
        return pos < 0 ? [] : name[pos :]->split('\ze\.')
    enddef

    def Stem(): string
        var name: string = this.Name()
        var suffix: string = this.Suffix()
        return name->slice(0, name->len() - suffix->len())
    enddef

    def Native(): string
        return (this.IsProtocol() || !windows) ? this.posix :
            this.posix->tr('/', '\')
    enddef

    # whether this path has sub-file {path}
    def Contains(a_path: any): bool
        var p = Path.new(a_path)
        return p.Resolve().path->stridx(this.Resolve().path) == 0
    enddef

    def RelativeTo(a_other: any): Path
        var other = Path.new(a_other).Resolve()
        var op: string = other.posix
        var oa: string = other.Anchor().posix
        var path: string = this.Resolve().posix
        var head: string = ''
        while 1
            if path->stridx(op) == 0
                path = path[op->len() :]
                if path =~ '\v^/'
                    path = path[1 :]
                endif
                return Path.new(head .. path)
            endif

            if op->len() <= oa->len()
                break
            endif
            op = op->slice(0, op->strridx('/'))
            head = '../' .. head
        endwhile
        throw $'no common part in ''{this.path}'' and ''{Path.new(a_other).path}'''
    enddef

    def WithName(a_name: string): Path
        var name: string = this.Name()
        if name->empty()
            throw $'{this.path} has an empty name'
        endif
        return Path.new(this.path->slice(0, -(name->len())) .. a_name)
    enddef

    def WithStem(a_stem: string): Path
        var name: string = this.Name()
        var suffix: string = this.Suffix()
        if name->empty()
            throw $'{this.path} has an empty name'
        endif
        return Path.new(this.path->slice(0, -(name->len())) .. a_stem .. suffix)
    enddef

    def WithSuffix(a_suffix: string): Path
        if a_suffix !~ '\v^\.' && !a_suffix->empty()
            throw $'invalid suffix ''{a_suffix}'''
        endif
        var suffix: string = this.Suffix()
        return Path.new(this.path[: -(suffix->len() + 1)] .. a_suffix)
    enddef

    def IsSamefile(other: any): bool
        return this.Resolve(1).path == Path.new(other).Resolve(1).path
    enddef

    # :h mkdir
    def Mkdir(mode: number = 0o755, flags: string = ''): number
        return this.Resolve().posix->mkdir(flags, mode)
    enddef

    def Unlink(): number
        if this.IsDir()
            return this.Rmdir()
        endif
        return this.Resolve().posix->delete()
    enddef

    def Rmdir(): number
        return this.Resolve().posix->delete('d')
    enddef
endclass


# Change dir {{{ #
export def GetCdCmd(): string
    return haslocaldir() ? (haslocaldir() == 1 ? 'lcd' : 'tcd') : 'cd'
enddef


export def Chdir(p: string): void
    silent exec $'{GetCdCmd()} {fnameescape(p)}'
enddef


export def ChdirNoAutocmd(p: string): void
    noautocmd Chdir(p)
enddef
# }}} Change dir #


# Testing suit. {{{ #
if 0
    import autoload './debug.vim'

    var Assert = debug.Assert
    var MdEqual = debug.Equal

    def TestAsPosix(): bool
        return MdEqual(AsPosix('c:\a\b'), 'c:/a/b') &&
            MdEqual(AsPosix('c:\\a\\\\b'), 'c:/a/b') &&
            MdEqual(AsPosix('////////'), '/') &&
            MdEqual(AsPosix('/a/'), '/a') && MdEqual(AsPosix('./'), '.') &&
            MdEqual(AsPosix('../'), '..') &&
            MdEqual(AsPosix('///a////'), '/a') &&
            MdEqual(AsPosix('.//'), '.') &&
            MdEqual(AsPosix('..///'), '..') &&
            MdEqual(AsPosix('\\a\\\b'), '//a/b') &&
            MdEqual(AsPosix('\\192.168.1.1/a'), '//192.168.1.1/a') &&
            MdEqual(AsPosix('//a/b/'), '//a/b') &&
            MdEqual(AsPosix('//a////b'), '//a/b') &&
            MdEqual(AsPosix('ftp://a'), 'ftp://a') &&
            MdEqual(AsPosix('http://a//'), 'http://a') &&
            MdEqual(AsPosix('//'), '//')
    enddef

    def TestPathType(): bool
        return P('\\a\b').IsUnc()->Assert() &&
            (!P('\a\b').IsUnc())->Assert() &&
            P('ab://abc////').IsProtocol()->Assert() &&
            (!P('ab:://ab').IsProtocol())->Assert() &&
            (windows == !P('/a').IsAbsolute())->Assert() &&
            (windows == P('a:/b').IsAbsolute())->Assert() &&
            (windows == P('a:').IsAbsolute())->Assert() &&
            (windows == P('a://').IsAbsolute())->Assert() &&
            (!P('//').IsAbsolute())->Assert() &&
            P('./').IsRelative()->Assert() &&
            P('../').IsRelative()->Assert() &&
            P('.').IsRelative()->Assert() &&
            P('..').IsRelative()->Assert() &&
            (windows == P('/a').IsRelative())->Assert()
    enddef

    def TestParse(): bool
        # should throw except
        # echo P('c:/etc').RelativeTo('d:/usr')
        # echo P('c:/').WithName('a.vim')
        # echo P('c:/').WithStem('a')
        return P('/a/b///').Resolve().Native()
            ->MdEqual('/a/b'->fnamemodify(':p')) &&
            P('a/b/c').Native()->MdEqual(windows ? '.\a\b\c' : './a/b/c') &&
            P('/a/b').Contains('/a/b/c')->Assert() &&
            (!P('/a/b').Contains('/a'))->Assert() &&
            P('/etc/passwd').RelativeTo('/')->string()->MdEqual('etc/passwd') &&
            P('/etc/passwd').RelativeTo('/etc')->string()->MdEqual('passwd') &&
            P('c:/d/e.tar.gz').WithName('a.vim')->string()->MdEqual('c:/d/a.vim') &&
            P('c:/a/b.txt').WithStem('c')->string()->MdEqual('c:/a/c.txt') &&
            P('c:/a/b.tar.gz').WithStem('c')->string()->MdEqual('c:/a/c.gz') &&
            P('c:/a/b.tar.gz').WithSuffix('.bz2')->string()->MdEqual('c:/a/b.tar.bz2') &&
            P('c:/a/b').WithSuffix('.txt')->string()->MdEqual('c:/a/b.txt') &&
            P('c:/a/b.txt').WithSuffix('')->string()->MdEqual('c:/a/b') &&
            Home()->string()->MdEqual(expand('~')) &&
            Cwd()->string()->MdEqual(expand('.'))
    enddef

    def TestParts(): bool
        return P('//server').Drive()->string()->MdEqual('//server') &&
            P('//server/share').Drive()->string()->MdEqual('//server/share') &&
            P('//server/share/a').Drive()->string()->MdEqual('//server/share') &&
            P('ftp://a').Drive()->string()->MdEqual('') &&
            P('c:/a/').Root()->string()->MdEqual('/') &&
            P('c:a').Root()->string()->MdEqual('') &&
            P('/').Root()->string()->MdEqual('/') &&
            P('ftp://a').Root()->string()->MdEqual('') &&
            P('c:/a/b').Anchor()->string()->MdEqual('c:/') &&
            P('c:a/b').Anchor()->string()->MdEqual('c:') &&
            P('/etc').Anchor()->string()->MdEqual('/') &&
            P('.').Anchor()->empty()->Assert() &&
            P('..').Anchor()->empty()->Assert() &&
            P().Anchor()->empty()->Assert() &&
            P('\\host/share').Anchor()->string()->MdEqual('//host/share/') &&
            P('ftp://a').Anchor()->string()->MdEqual('') &&
            P('/usr/bin/python3').Parts()->MdEqual(['/', 'usr', 'bin', 'python3']) &&
            P('c:\\Program Files/PSF').Parts()->MdEqual(['c:/', 'Program Files', 'PSF']) &&
            P('ftp://a').Parts()->MdEqual(['ftp:', 'a']) &&
            P('/a/b/c/d').Parent()->string()->MdEqual('/a/b/c') &&
            P('/').Parent()->string()->MdEqual('/') &&
            P('.').Parent()->string()->MdEqual('.') &&
            P('').Parent()->string()->MdEqual('.') &&
            P('c:/foo/bar/setup.py').Parents()->copy()
            ->map((_, v) => v->string())->MdEqual([
                'c:/foo/bar', 'c:/foo', 'c:/'
            ]) &&
            P('/a/b/c').Parents()->copy()->map((_, v) => v->string())
            ->MdEqual(['/a/b', '/a', '/']) &&
            P('my/library/setup.py').Name()->MdEqual('setup.py') &&
            P('//some/share/setup.py').Name()->MdEqual('setup.py') &&
            P('//some/share/').Name()->MdEqual('') &&
            P('my/library/a.vim').Suffix()->MdEqual('.vim') &&
            P('my/library/a.tar.gz').Suffix()->MdEqual('.gz') &&
            P('my/library').Suffix()->MdEqual('') &&
            P('my/library/.ignore').Suffix()->MdEqual('') &&
            P('my/library/a.').Suffix()->MdEqual('.') &&
            P('my/library.tar.gz').Suffixes()->MdEqual(['.tar', '.gz']) &&
            P('my/library').Suffixes()->MdEqual([]) &&
            P('my/library.tar.gz').Stem()->MdEqual('library.tar') &&
            P('my/library.tar').Stem()->MdEqual('library') &&
            P('my/library').Stem()->MdEqual('library')
    enddef


    def TestJoinpath(): bool
        return P('/a').Joinpath(P('b'), P('c/d'))->string()->MdEqual('/a/b/c/d') &&
            P('/a').Joinpath('/b')->string()->MdEqual(windows ? '/a/b' : '/b')
    enddef

    def TestIsPath(): bool
        return Assert(IsPath('.')) && Assert(IsPath('..')) &&
            Assert(IsPath('./')) && Assert(IsPath('../')) &&
            Assert(IsPath('./a')) && Assert(IsPath('../a')) &&
            Assert(IsPath('./a/..')) && Assert(IsPath('../a/..')) &&
            Assert(IsPath('...')) &&
            Assert(IsPath('C:/')) && Assert(IsPath('C:\\')) &&
            Assert(IsPath('C:/a')) && Assert(IsPath('C:\\a')) &&
            Assert(IsPath('C:/a\\..')) && Assert(IsPath('C:\\a/..')) &&
            Assert(IsPath('/tmp')) && Assert(IsPath('/tmp/')) &&
            Assert(IsPath('/tmp/..')) && Assert(IsPath('/tmp\\..')) &&
            Assert(IsPath('https://')) && Assert(IsPath(''))
    enddef

    def Test(): void
        TestIsPath() &&
            TestAsPosix() &&
            TestPathType() &&
            TestParse() &&
            TestParts() &&
            TestJoinpath()
    enddef

    Test()
endif
# }}} Testing suit. #
