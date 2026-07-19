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
# NOTE:
#   1) if {path} is empty, return '.'
#   2) the trailing './' will be removed except './' which will return '.'
#   3) if it's not a absolute path, a leading './' will be add
export def AsPosix(a_path: string, lower: bool = false): string
    if empty(a_path) | return '.' | endif
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
        if lower && (windows || has('win32unix'))
            path = tolower(path)
        endif
    endif
    # if not absolute path, assume that it is in current directory
    if path !~ '\v^(/|\.|(\a+:))'
        path = './' .. path
    endif
    # ./././ => ./
    path->ms.Replace('\v(\./)+', './')
    # ./.. => ..
    path->ms.Replace('\V./..', '..')
    # ../. => ..
    path->ms.Replace('\V../.', '..')
    # careful for // and c:/  (c:/ != c:)
    if path =~ '\v([^/:])/$'
        path = path[: -2]
    endif
    return path
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


class Path
    var path: string = null_string  # raw as user input
    var posix: string = null_string  # store as posix style

    def new(a_path: any = null)
        if a_path == null
            return
        endif

        if a_path->type() == v:t_string
            this.path = a_path->ExpandPath()
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


    def _JoinTwoPath(a: Path, b: Path): Path
        if a->empty() | return b | endif
        if b->empty() | return a | endif

        if b.IsAbsolute()
            return Path.new(b)
        endif

        var bp: string = b.posix
        # ignore all '.' and './'
        if bp == '.'
            bp = ''
        endif
        if bp =~ '\v^\./'
            bp = bp[2 :]
        endif

        var path: string = a.posix
        if path[-1] != '/' && (bp !~ '\v^/')
            path ..= '/'
        endif
        return Path.new(path .. bp)
    enddef

    def Joinpath(...paths: list<any>): Path
        var np = Path.new(this)
        for p in paths
            np = this._JoinTwoPath(np, Path.new(p))
        endfor
        return np
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
        var anchor: string = this.Anchor().posix
        var pos = this.posix[anchor->len() :]->strridx('/')
        return pos < 0 ? '' : this.posix[anchor->len() :][pos + 1 :]
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

    def IterDir(): list<Path>
        if !this.IsDir()
            throw $'{this.path} is not a directory'
        endif
        return readdir(this.posix)->map((_, v) => Path.new(this.path .. '/' .. v))
    enddef

    def IsSamefile(other: Path): bool
        return this.Resolve(1).path == other.Resolve(1).path
    enddef

    # :h mkdir
    def Mkdir(mode: number = 0o755, flags: string = ''): number
        return this.Resolve().posix->mkdir(flags, mode)
    enddef

    def Unlink(): void
        if this.IsDir()
            return this.Rmdir()
        endif
        return this.Resolve().posix->delete()
    enddef

    def Rmdir(): number
        return this.Resolve().posix->delete('d')
    enddef
endclass

var P = Path.new

export def Home(): Path
    return P('~')
enddef

export def Cwd(): Path
    return P('.')
enddef

export def IsPath(a_path: string): bool
    return P(a_path).IsPath()
enddef

export def IsDir(a_path: string): bool
    return P(a_path).IsDir()
enddef

export def IsFile(a_path: string): bool
    return P(a_path).IsFile()
enddef


# return the name of entry
export def IterDir(dir: string): list<string>
    return readdir(dir)
enddef


export def Absolute(a_path: string): string
    return P(a_path).Resolve().Native()
enddef


export def IsAbsolute(a_path: string): bool
    return P(a_path).IsAbsolute()
enddef


#--------------------------------------------------------------
# python: os.path.join
#--------------------------------------------------------------
export def Joinpath(...paths: list<string>): string
    if paths->empty()
        return ''
    endif
    return P(path[0]).Joinpath(paths[1 :])
enddef


#----------------------------------------------------------------------
# dirname
#----------------------------------------------------------------------
export def Parent(path: string): string
    return fnamemodify(path, ':h')
enddef


#----------------------------------------------------------------------
# basename of /foo/bar is bar
#----------------------------------------------------------------------
export def Name(path: string): string
    return fnamemodify(path, ':t')
enddef


#----------------------------------------------------------------------
# resolve the {path}, return the native format
# {lower} Whether to translate to uppercase to lowercase, useful when
#         on Windows, default: false
#----------------------------------------------------------------------
export def Resolve(path: string, lower: bool = false): string
    return P(path).Resolve().Native()
enddef


export def IsSamefile(path1: string, path2: string): bool
    if path1 == path2
        return true
    endif
    return P(path1).IsSamefile(path2)
enddef


#----------------------------------------------------------------------
# return true if base directory contains child
#----------------------------------------------------------------------
export def Contains(base: string, child: string): bool
    return P(base).Contains(child)
enddef


#----------------------------------------------------------------------
# return a relative version of a path
#----------------------------------------------------------------------
export def Relpath(path: string, base: string = null_string): string
    return P(path).RelativeTo(base)
enddef


#----------------------------------------------------------------------
# exists
#----------------------------------------------------------------------
export def Exists(path: string): bool
    return P(path).Exists()
enddef


#----------------------------------------------------------------------
# Shorten({path} [, {limit}])
# shorten path
# {limit} The path length limit, default: 40
#----------------------------------------------------------------------
export def Shorten(a_path: string, limit: number = 40): string
    var home: string = expand('~')
    var path: string = a_path
    if path->stridx(home) == 0
        path = '~' .. path->slice(home->strlen())
    endif
    var size: number = path->strlen()
    if size > limit
        path = path->pathshorten(2)
        if path->strlen() > limit
            return path->pathshorten()
        endif
    endif
    return path
enddef


# Testing suit. {{{ #
if 1
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
            P('a:/b').IsAbsolute()->Assert() &&
            P('a:').IsAbsolute()->Assert() &&
            P('a://').IsAbsolute()->Assert() &&
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
            P('a/b/c').Native()->MdEqual('.\a\b\c') &&
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
