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
    # NOTE: this is different from Windows native behavior,
    # Windows treat 'C:' as relative path point to the folder what
    # is last active on the 'C:' drive, but Vim treat 'C:' the same
    # as 'C:/', try :echo fnamemodify('c:', ':p')
    return a_path->empty() || a_path->stridx(':') < 0
enddef

def IsRelativePosix(a_path: string): bool
    return a_path->empty() || a_path[0] != '/'
enddef

def IsAbsoluteWin(a_path: string): bool
    return !IsRelativeWin(a_path)
enddef

def IsAbsolutePosix(a_path: string): bool
    return !IsRelativePosix(a_path)
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
    path = path->mStr.Replace('\v(\./)+', './')
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

    if IsRelative(path)
            && path !~ '\v^(\.|\.\.)($|/)'
            && (!s_win || path !~ '\v^/')
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

export def IsFile(a_path: string, followSymlinks: bool = true): bool
    var ftype: string = getftype(a_path)
    return ftype == 'file'
        || (followSymlinks && ftype == 'link' && filereadable(a_path))
enddef

export def IsDir(a_path: string, followSymlinks: bool = true): bool
    var ftype: string = getftype(a_path)
    return ftype == 'dir' ||
        (followSymlinks && ftype == 'link' && isdirectory(a_path))
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
        other = newOther

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
    var path: string

    # these method should be static method, but now vim9script
    # interface do not support static method
    def Home(): Path
    def Cwd(): Path

    def IsAbsolute(): bool
    def IsRelative(): bool

    def AsPosix(lower: bool): string

    def IsFile(followSymlinks: bool = true): bool
    def IsDir(followSymlinks: bool = true): bool
    def IsSymlink(): bool
    def IsBlockDevice(): bool
    def IsCharDevice(): bool
    def IsSocket(): bool
    def IsFifo(): bool

    def Iterdir(): list<Path>

    def Joinpath(...paths: list<any>): Path

    def Resolve(lower: bool = false): Path

    def Drive(): string
    def Root(): string
    def Anchor(): string

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


export class PosixPath implements Path
    var _raw: string
    var path: string
    var _ftype: string = null_string

    def string(): string
        return this._raw
    enddef

    def new(a_path: any = '.')
        if type(a_path) == v:t_string
            this._raw = a_path->empty() ? '.' : a_path
            this.path = AsPosix(this._raw)
        elseif type(a_path) == v:t_object && a_path->instanceof(Path)
            this._raw = a_path._raw
            this.path = a_path.path
        else
            throw $'invalid param'
        endif
    enddef

    def _newRawPath(a_raw: string, a_path: string)
        this._raw = a_raw
        this.path = a_path
    enddef


    def Home(): Path
        return PosixPath.new(Home())
    enddef

    def Cwd(): Path
        return PosixPath.new(Cwd())
    enddef


    def IsAbsolute(): bool
        return IsAbsolutePosix(this.path)
    enddef

    def IsRelative(): bool
        return IsRelativePosix(this.path)
    enddef


    def AsPosix(lower: bool = false): string
        return lower ? this.path->tolower() : this.path
    enddef


    def IsFile(followSymlinks: bool = true): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'file' ||
            (followSymlinks && this._ftype == 'link' && filereadable(this.path))
    enddef

    def IsDir(followSymlinks: bool = true): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'dir' ||
            (followSymlinks && this._ftype == 'link' && isdirectory(this.path))
    enddef

    def IsSymlink(): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'link'
    enddef

    def IsBlockDevice(): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'bdev'
    enddef

    def IsCharDevice(): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'cdev'
    enddef

    def IsSocket(): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'socket'
    enddef

    def IsFifo(): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'fifo'
    enddef


    def Iterdir(): list<Path>
        if !this.IsDir()
            throw $'not a directory'
        endif
        return readdir(this.path)
            ->map((_, v) => PosixPath.new(this).Joinpath(v))
    enddef


    static def _String(a_path: any): string
        if a_path->type() == v:t_string
            return a_path
        elseif a_path->type() == v:t_object && a_path->instanceof(Path)
            return a_path.path
        else
            throw 'invalid param'
        endif
    enddef


    def Joinpath(...paths: list<any>): Path
        var path: string = this.path
        for p in paths
            var np: string = PosixPath._String(p)->AsPosix()
            path = JoinTwoPath(path, np)
        endfor
        return PosixPath._newRawPath(path, path)
    enddef


    def Resolve(lower: bool = false): Path
        var path: string = DoResolve(this.path, lower)
        return PosixPath._newRawPath(path, path)
    enddef


    def Drive(): string
        return ''
    enddef

    def Root(): string
        return this.IsAbsolute() ? '/' : ''
    enddef

    def Anchor(): string
        return this.Root()
    enddef

    def Parts(): list<string>
        var anchor: string = this.Anchor()
        return [anchor] + this.path->slice(len(anchor))->split('/', 0)
    enddef

    def Parent(): Path
        var path: string = this.path->fnamemodify(':h')
        return PosixPath._newRawPath(path, path)
    enddef

    def Parents(): list<Path>
        var parents: list<Path> = []
        var p: Path = this

        while 1
            var pp: string = p.path->fnamemodify(':h')
            if pp == p.path
                break
            endif
            p = PosixPath._newRawPath(pp, pp)
            parents->add(p)
        endwhile

        return parents
    enddef

    def Name(): string
        return this.path->fnamemodify(':t')
    enddef

    def Suffix(): string
        return this.path->fnamemodify(':e')
    enddef

    def Suffixes(): list<string>
        var name: string = this.Name()
        var pos = name->stridx('.', 1)  # handle with dot file
        return pos < 0 ? [] : name->slice(pos)->split('\ze\.')
    enddef

    def Stem(): string
        return this.path->fnamemodify(':t:r')
    enddef

    def IsSamefile(other: any): bool
        return IsSamefile(this.path, PosixPath._String(other))
    enddef

    def Exists(): bool
        return Exists(this.path)
    enddef

    def RelativeTo(a_other: any): Path
        var other: string = PosixPath._String(a_other)
        var np: string = RelativeTo(this.path, other)
        return PosixPath.new(np)
    enddef

    def WithName(a_name: string): Path
        var name: string = this.Name()
        if name->empty() || a_name->empty()
            throw $'empty name'
        endif

        var np: string = JoinTwoPath(this.path->slice(0, -len(name)), a_name)
        return PosixPath._newRawPath(np, np)
    enddef

    def WithStem(a_stem: string): Path
        var name: string = this.Name()
        if empty(name) || empty(a_stem)
            throw 'empty name/stem'
        endif

        var suffix: string = this.Suffix()
        var np: string = JoinTwoPath(this.path->slice(0, -len(name)),
            $'{a_stem}.{suffix}')
        return PosixPath._newRawPath(np, np)
    enddef

    def WithSuffix(a_suffix: string): Path
        var suffix: string = this.Suffix()
        var np: string = empty(suffix) ? this.path :
            this.path->slice(0, -len(suffix) - 1)  # remove the tailing '.'
        np = $'{np}{empty(a_suffix) ? '' : '.'}{a_suffix}'
        return PosixPath._newRawPath(np->AsNative(), np)
    enddef

    def Mkdir(mode: number = 0o755, flags: string = ''): number
        return Mkdir(this.path, mode, flags)
    enddef

    def Unlink(): number
        return Unlink(this.path)
    enddef

    def Rmdir(): number
        return Rmdir(this.path)
    enddef
endclass


export class WinPath implements Path
    var _raw: string
    var path: string
    var _ftype: string = null_string

    def string(): string
        return this._raw
    enddef

    def new(a_path: any = '.')
        if type(a_path) == v:t_string
            this._raw = a_path->empty() ? '.' : a_path
            this.path = AsPosix(this._raw)
            this._raw = this.path->AsNative()
        elseif type(a_path) == v:t_object && a_path->instanceof(Path)
            this._raw = a_path._raw
            this.path = a_path.path
        else
            throw $'invalid param'
        endif
    enddef

    def _newRawPath(a_raw: string, a_path: string)
        this._raw = a_raw
        this.path = a_path
    enddef


    def Home(): Path
        return WinPath.new(Home())
    enddef

    def Cwd(): Path
        return WinPath.new(Cwd())
    enddef


    def IsAbsolute(): bool
        return IsAbsoluteWin(this.path)
    enddef

    def IsRelative(): bool
        return IsRelativeWin(this.path)
    enddef


    def AsPosix(lower: bool = false): string
        return lower ? this.path->tolower() : this.path
    enddef


    def IsFile(followSymlinks: bool = true): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'file' ||
            (followSymlinks && this._ftype == 'link' && filereadable(this.path))
    enddef

    def IsDir(followSymlinks: bool = true): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'dir' &&
            (followSymlinks && this._ftype == 'link' && isdirectory(this.path))
    enddef

    def IsSymlink(): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'link'
    enddef

    def IsBlockDevice(): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'bdev'
    enddef

    def IsCharDevice(): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'cdev'
    enddef

    def IsSocket(): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'socket'
    enddef

    def IsFifo(): bool
        if this._ftype == null
            this._ftype = getftype(this.path)
        endif
        return this._ftype == 'fifo'
    enddef


    def Iterdir(): list<Path>
        if !this.IsDir()
            throw $'not a directory'
        endif
        return readdir(this.path)
            ->map((_, v) => WinPath.new(this).Joinpath(v))
    enddef


    static def _String(a_path: any): string
        if a_path->type() == v:t_string
            return a_path
        elseif a_path->type() == v:t_object && a_path->instanceof(Path)
            return a_path.path
        else
            throw 'invalid param'
        endif
    enddef


    def Joinpath(...paths: list<any>): Path
        var path: string = this.path
        for p in paths
            var np: string = WinPath._String(p)->AsPosix()
            path = JoinTwoPath(path, np)
        endfor
        return WinPath._newRawPath(path->AsNative(), path)
    enddef


    def Resolve(lower: bool = false): Path
        var path: string = DoResolve(this.path, lower)
        return WinPath._newRawPath(path->AsNative(), path)
    enddef


    def Drive(): string
        return this.IsAbsolute() ? this.path->slice(0, 2) : ''
    enddef

    def Root(): string
        return (this.IsAbsolute() || (this.path =~ '\v^/'))
            ? '/'->AsNative() : ''
    enddef

    def Anchor(): string
        return JoinTwoPath(this.Drive(), this.Root())->AsNative()
    enddef

    def Parts(): list<string>
        var anchor: string = this.Anchor()
        var parts: list<string> = [anchor] +
            this.path->slice(len(anchor))->split('/', 0)
        return parts->map((_, v) => AsNative(v))
    enddef

    def Parent(): Path
        var path: string = this.path->fnamemodify(':h')
        return WinPath._newRawPath(path->AsNative(), path)
    enddef

    def Parents(): list<Path>
        var parents: list<Path> = []
        var p: Path = this

        while 1
            var pp: string = p.path->fnamemodify(':h')
            if pp == p.path
                break
            endif
            p = WinPath._newRawPath(pp->AsNative(), pp)
            parents->add(p)
        endwhile

        return parents
    enddef

    def Name(): string
        return this.path->fnamemodify(':t')
    enddef

    def Suffix(): string
        return this.path->fnamemodify(':e')
    enddef

    def Suffixes(): list<string>
        var name: string = this.Name()
        var pos = name->stridx('.', 1)  # handle with dot file
        return pos < 0 ? [] : name->slice(pos)->split('\ze\.')
    enddef

    def Stem(): string
        return this.path->fnamemodify(':t:r')
    enddef

    def IsSamefile(other: any): bool
        return IsSamefile(this.path, WinPath._String(other))
    enddef

    def Exists(): bool
        return Exists(this.path)
    enddef

    def RelativeTo(a_other: any): Path
        var other: string = WinPath._String(a_other)
        var np: string = RelativeTo(this.path, other)
        return WinPath.new(np->AsNative())
    enddef

    def WithName(a_name: string): Path
        var name: string = this.Name()
        if name->empty() || a_name->empty()
            throw $'empty name'
        endif

        var np: string = JoinTwoPath(this.path->slice(0, -len(name)), a_name)
        return WinPath._newRawPath(np->AsNative(), np)
    enddef

    def WithStem(a_stem: string): Path
        var name: string = this.Name()
        if empty(name) || empty(a_stem)
            throw 'empty name/stem'
        endif

        var suffix: string = this.Suffix()
        var np: string = JoinTwoPath(this.path->slice(0, -len(name)),
            $'{a_stem}.{suffix}')
        return WinPath._newRawPath(np->AsNative(), np)
    enddef

    def WithSuffix(a_suffix: string): Path
        var suffix: string = this.Suffix()
        var np: string = empty(suffix) ? this.path :
            this.path->slice(0, -len(suffix) - 1)  # remove the tailing '.'
        np = $'{np}{empty(a_suffix) ? '' : '.'}{a_suffix}'
        return WinPath._newRawPath(np->AsNative(), np)
    enddef

    def Mkdir(mode: number = 0o755, flags: string = ''): number
        return Mkdir(this.path, mode, flags)
    enddef

    def Unlink(): number
        return Unlink(this.path)
    enddef

    def Rmdir(): number
        return Rmdir(this.path)
    enddef
endclass


export def New(a_path: any = '.'): Path
    return s_win ? WinPath.new(a_path) : PosixPath.new(a_path)
enddef


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
    var P = New

    def TestAsPosix(): bool
        return (!s_win || MdEqual(AsPosix('c:\a\b'), 'c:/a/b')) &&
            (!s_win || MdEqual(AsPosix('c:\\a\\\\b'), 'c:/a/b')) &&
            MdEqual(AsPosix('////////'), '/') &&
            MdEqual(AsPosix('/a/'), '/a') && MdEqual(AsPosix('./'), '.') &&
            MdEqual(AsPosix('../'), '..') &&
            MdEqual(AsPosix('///a////'), '/a') &&
            MdEqual(AsPosix('.//'), '.') &&
            MdEqual(AsPosix('..///'), '..')
    enddef

    def TestPathType(): bool
        return (s_win == !P('/a').IsAbsolute())->Assert() &&
            (s_win == P('a:/b').IsAbsolute())->Assert() &&
            (s_win == P('a:').IsAbsolute())->Assert() &&
            (s_win == P('a://').IsAbsolute())->Assert() &&
            (s_win != P('/').IsAbsolute())->Assert() &&
            P('./').IsRelative()->Assert() &&
            P('../').IsRelative()->Assert() &&
            P('.').IsRelative()->Assert() &&
            P('..').IsRelative()->Assert() &&
            (s_win == P('/a').IsRelative())->Assert()
    enddef

    def TestParse(): bool
        # should throw except
        # echo P('c:/etc').RelativeTo('d:/usr')
        # echo P('c:/').WithName('a.vim')
        # echo P('c:/').WithStem('a')

        return P('/a/b///').Resolve()->string()
            ->MdEqual('/a/b'->fnamemodify(':p')) &&
            P('a/b/c').path->MdEqual('./a/b/c') &&
            P('/etc/passwd').RelativeTo('/').path->MdEqual('./etc/passwd') &&
            P('/etc/passwd').RelativeTo('/etc').path->MdEqual('./passwd') &&
            P('d/e.tar.gz').WithName('a.vim').path->MdEqual('./d/a.vim') &&
            P('a/b.txt').WithStem('c').path->MdEqual('./a/c.txt') &&
            P('a/b.tar.gz').WithStem('c').path->MdEqual('./a/c.gz') &&
            P('a/b.tar.gz').WithSuffix('bz2').path
                ->MdEqual('./a/b.tar.bz2') &&
            P('a/b').WithSuffix('txt').path->MdEqual('./a/b.txt') &&
            P('a/b.txt').WithSuffix('').path->MdEqual('./a/b') &&
            Home()->MdEqual(expand('~')) &&
            Cwd()->MdEqual(fnamemodify('.', ':p'))
    enddef

    def TestParts(): bool
        return (!s_win ||
                (P('c:/a/').Root()->MdEqual('/') &&
                P('c:a').Root()->MdEqual('/')) &&
                P('c:\\Program Files/PSF').Parts()->MdEqual(['c:/', 'Program Files', 'PSF']) &&
                P('c:/foo/bar/setup.py').Parents()->copy()
                ->map((_, v) => v.path)->MdEqual([
                    'c:/foo/bar', 'c:/foo', 'c:/'
                ]) &&
                P('c:/a/b').Anchor()->MdEqual('c:/') &&
                P('c:a/b').Anchor()->MdEqual('c:/')
            ) &&
            P('/').Root()->MdEqual('/') &&
            P('/etc').Anchor()->MdEqual('/') &&
            P('.').Anchor()->empty()->Assert() &&
            P('..').Anchor()->empty()->Assert() &&
            P().Anchor()->empty()->Assert() &&
            P('/usr/bin/python3').Parts()->MdEqual(['/', 'usr', 'bin', 'python3']) &&
            P('/a/b/c/d').Parent().path->MdEqual('/a/b/c') &&
            P('/').Parent().path->MdEqual('/') &&
            P('.').Parent().path->MdEqual('.') &&
            P('').Parent().path->MdEqual('.') &&
            P('/a/b/c').Parents()->copy()->map((_, v) => v.path)
            ->MdEqual(['/a/b', '/a', '/']) &&
            P('my/library/setup.py').Name()->MdEqual('setup.py') &&
            P('my/library/a.vim').Suffix()->MdEqual('vim') &&
            P('my/library/a.tar.gz').Suffix()->MdEqual('gz') &&
            P('my/library').Suffix()->MdEqual('') &&
            P('my/library/.ignore').Suffix()->MdEqual('') &&
            P('my/library/a.').Suffix()->MdEqual('') &&
            P('my/library.tar.gz').Suffixes()->MdEqual(['.tar', '.gz']) &&
            P('my/library').Suffixes()->MdEqual([]) &&
            P('my/library.tar.gz').Stem()->MdEqual('library.tar') &&
            P('my/library.tar').Stem()->MdEqual('library') &&
            P('my/library').Stem()->MdEqual('library')
    enddef


    def TestJoinpath(): bool
        return P('/a').Joinpath(P('b'), P('c/d'))->string()
            ->MdEqual('/a/b/c/d')
            && P('/a').Joinpath('/b')->string()->MdEqual(s_win ? '/a/b' : '/b')
    enddef

    def TestIsPath(): bool
        return Assert(IsPath('.')) && Assert(IsPath('..')) &&
            Assert(IsPath('./')) && Assert(IsPath('../')) &&
            Assert(IsPath('./a')) && Assert(IsPath('../a')) &&
            Assert(IsPath('./a/..')) && Assert(IsPath('../a/..')) &&
            Assert(IsPath('...')) &&
            Assert(s_win == IsPath('C:/')) &&
            Assert(s_win == IsPath('C:\\')) &&
            Assert(s_win == IsPath('C:/a')) &&
            Assert(s_win == IsPath('C:\\a')) &&
            Assert(s_win == IsPath('C:/a\\..')) &&
            Assert(s_win == IsPath('C:\\a/..')) &&
            Assert(IsPath('/tmp')) && Assert(IsPath('/tmp/')) &&
            Assert(IsPath('/tmp/..')) && Assert(s_win == IsPath('/tmp\\..'))
    enddef

    def Test(): void
        var savedShellslash = &shellslash
        set shellslash
        defer () => {
            &shellslash = savedShellslash
        }()
        TestIsPath()
            && TestAsPosix()
            && TestPathType()
            && TestParse()
            && TestParts()
            && TestJoinpath()
    enddef

    Test()

endif
# }}} Testing suit. #
