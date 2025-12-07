vim9script

# From https://github.com/girishji/vimcomplete/

import autoload './util.vim'
import autoload '../util/notify.vim'
import autoload '../util/os.vim'
import autoload '../util/path.vim'

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
        if prefix->empty() || !prefix->path.IsPath()
            return -2
        endif
        # to inclue the leading '.'
        return col('.') - (strlen(prefix) + 1)
    endif

    var cItems = []
    var dirChanged: bool = false
    try
        if options.bufRelPath && base =~ ('^\v\.\.?' .. path.sepPatern) &&
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
                abbr: cItem->path.Basename() .. (isDir && options.showPathSepAtEnd ? '/' : ''),
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
    return {words: cItems, refresh: 'always'}
enddef

def UpdateCwd(): void
    cwd = path.Abspath('.')
    bufInCwd = path.Equal(cwd, bufDir)
enddef

def UpdateBufDir(): void
    bufDir = path.Abspath('%')
    if !path.IsDir(bufDir)
        bufDir = path.Dirname(bufDir)
    endif
    bufInCwd = path.Equal(cwd, bufDir)
enddef

UpdateCwd()
UpdateBufDir()

augroup VcAutoloadCmpUtilPath
    au!
    au DirChanged * UpdateCwd()
    au BufEnter * UpdateBufDir()
augroup END
