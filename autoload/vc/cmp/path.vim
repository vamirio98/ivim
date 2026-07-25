vim9script

# From https://github.com/girishji/vimcomplete/

import autoload './util.vim'
import autoload '../util/notify.vim'
import autoload '../util/os.vim'
import autoload '../util/path.vim'
# import autoload '../util'

type Path = path.Path

export var opts: dict<any> = {
    enable: true,
    groupDirFirst: false,
    showPathSepAtEnd: true,
    # always ignore case on Windows
    smartCase: true,  # if false, case sensitive on Unix
}

# export def Completor(findstart: number, base: string): any
#     if findstart
#         if !opts.enable
#             return -2
#         endif
#         var line = getline('.')->strpart(0, col('.') - 1)
#         var prefix = line->matchstr('\f\+$')
#         var f = Path.new(prefix)
#         if f->empty() || f.IsUnc() || f.IsProtocol()
#             return -2
#         endif

#         return col('.') - strlen(prefix) - 1
#     endif

#     var t = reltime()
#     var cItems = []
#     var bufName: string = null_string
#     var bufDir: Path = null_object
#     var dir: Path = null_object
#     var fname: string = base =~ '\v/$' ? '' : Path.new(base).Name()
#     if base =~ '\v^\.'  # relative to current buffer
#         bufName = expand('%')
#         if bufName->len() > 0
#             bufDir = Path.new(expand('%:h')).Resolve()
#         else
#             bufDir = path.Cwd()
#         endif
#         dir = bufDir.Joinpath(base).Resolve()
#     else
#         dir = Path.new(base).Resolve()
#     endif
#     if base !~ '\v/$'
#         dir = dir.Parent()
#     endif

#     # HACK: vim9script now not support use class directly in matchfuzzy
#     # var matches = dir.IterDir()->matchfuzzy(f.Name(), { text_cb: (v) => v.Name() })
#     var matches: list<Path> = dir.IterDir()
#     if !fname->empty()
#         var candidates: list<any> = []
#         for fp in matches
#             candidates->add({ name: fp.Name(), file: fp })
#         endfor
#         matches = candidates->matchfuzzy(fname, { key: 'name' })
#             ->map((_, v) => v.file)
#     endif
#     if opts.groupDirFirst
#         matches = matches->copy()->filter((_, v) => v.IsDir()) +
#             matches->copy()->filter((_, v) => v.IsFile())
#     endif

#     for fp in matches
#         cItems->add({
#             word: base =~ '\v^\.' ? (base =~ '\v^\.([^\.]|$)' ? './' : '') ..
#                 fp.Resolve().RelativeTo(bufDir).posix : fp.posix,
#             abbr: fp.Name() .. ((fp.IsDir() && opts.showPathSepAtEnd) ? '/' : ''),
#             kind: util.GetItemKindValue(fp.IsDir() ? 'Folder' : 'File'),
#             kind_hlgroup: util.GetKindHighlightGroup(fp.IsDir() ? 'Folder' : 'File'),
#         })
#     endfor

#     echo t->reltime()->reltimestr()
#     return { words: cItems, refresh: 'always' }
# enddef
# TODO: find project root, and use it in relative path

### {{{
export var options: dict<any> = {
    enable: true,
    bufRelPath: true,
    groupDirFirst: false,
    showPathSepAtEnd: true,
}

var cwd: string = null_string
var bufDir: string = null_string
var bufInCwd: bool = true

export def Completor(findstart: number, base: string): any
    if findstart
        var line = getline('.')->strpart(0, col('.') - 1)
        var prefix = line->matchstr('\f\+$')
        var p = path.Path.new(prefix)
        if prefix->empty() || p.IsUnc() || p.IsProtocol()
            return -2
        endif
        return col('.') - (strlen(prefix) + 1)
    endif

    # var t = reltime()
    var cItems = []
    var dirChanged: bool = false
    try
        if options.bufRelPath && base =~ ('^\v\.\.?' .. path.sepPat) &&
                !bufInCwd
            # not already in buffer dir, change directory to get
            # completions for paths relative to current buffer dir
            os.ChdirNoAutocmd(bufDir)
            dirChanged = true
        endif

        def IsDir(p: string): bool
            return isdirectory(fnamemodify(p, ':p'))
        enddef
        # filter '.' and '..'
        var completions = getcompletion(base, 'file', 1)
            ->filter((_, v) => v !~ '\v^\.\.?$')
        if options.groupDirFirst
            completions = completions->copy()->filter((_, v) => IsDir(v)) +
                completions->copy()->filter((_, v) => !IsDir(v))
        endif
        for item in completions
            var cItem = item
            var itemLen = len(item)
            var isDir = IsDir(item)
            if isDir && item[itemLen - 1] == path.sep
                cItem = item->slice(0, itemLen - 1)
            endif
            cItems->add({
                word: cItem,
                abbr: cItem->path.Name() .. (isDir && options.showPathSepAtEnd ? '/' : ''),
                kind: util.GetItemKindValue(isDir ? 'Folder' : 'File'),
                kind_hlgroup: util.GetKindHighlightGroup(isDir ? 'Folder' : 'File'),
            })
        endfor
    catch
        # on MacOS it does not complete /tmp/* (throws E344, looks for /prevate/tmp/...)
        notify.Error(v:exception)
    finally
        if dirChanged
            os.ChdirNoAutocmd(cwd)
        endif
    endtry
    # echo t->reltime()->reltimestr()
    return {words: cItems, refresh: 'always'}
enddef

def UpdateCwd(): void
    cwd = path.Resolve('.')
    bufInCwd = path.IsSamefile(cwd, bufDir)
enddef

def UpdateBufDir(): void
    bufDir = path.Resolve('%')
    if !path.IsDir(bufDir)
        bufDir = path.Parent(bufDir)
    endif
    bufInCwd = path.IsSamefile(cwd, bufDir)
enddef

UpdateCwd()
UpdateBufDir()

augroup VcAutoloadCmpUtilPath
    au!
    au DirChanged * UpdateCwd()
    au BufEnter * UpdateBufDir()
augroup END
### }}}
