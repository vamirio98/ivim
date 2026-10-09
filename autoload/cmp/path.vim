vim9script

# From https://github.com/girishji/vimcomplete/

import autoload './util.vim' as mUtil

import autoload 'util/msg.vim' as mMsg
import autoload 'util/path.vim' as mPath

import autoload 'project/root.vim' as mRoot

### {{{
export var options: dict<any> = {
    enable: true,
    bufRelPath: true,
    groupDirFirst: false,
    showPathSepAtEnd: true,
}

class Ctx
    public var cwd: string = null_string
    public var bufDir: string = null_string
    public var bufInCwd: bool = false
endclass

var s_ctx = Ctx.new()

export def Completor(findstart: number, base: string): any
    if findstart
        var line = getline('.')->strpart(0, col('.') - 1)
        var prefix = line->matchstr('\f\+$')
        if prefix->empty() || !mPath.IsPath(prefix)
            return -2
        endif
        return col('.') - (strlen(prefix) + 1)
    endif

    # var t = reltime()
    var cItems = []
    var dirChanged: bool = false
    try
        if options.bufRelPath && base =~ ('^\v\.\.?' .. mPath.SepPat()) &&
                !s_ctx.bufInCwd
            # not already in buffer dir, change directory to get
            # completions for paths relative to current buffer dir
            mPath.ChdirNoAutocmd(s_ctx.bufDir)
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
            if isDir && item[itemLen - 1] == mPath.Sep()
                cItem = item->slice(0, itemLen - 1)
            endif
            cItems->add({
                word: cItem,
                abbr: cItem->mPath.Name() ..
                    (isDir && options.showPathSepAtEnd ? '/' : ''),
                kind: mUtil.GetItemKindValue(isDir ? 'Folder' : 'File'),
                kind_hlgroup: mUtil.GetKindHighlightGroup(isDir ? 'Folder' : 'File'),
            })
        endfor
    catch
        # on MacOS it does not complete /tmp/* (throws E344, looks for /prevate/tmp/...)
        mMsg.Error(v:exception)
    finally
        if dirChanged
            mPath.ChdirNoAutocmd(s_ctx.cwd)
        endif
    endtry
    # echo t->reltime()->reltimestr()
    return {words: cItems, refresh: 'always'}
enddef

def UpdateCwd(): void
    s_ctx.cwd = mPath.Resolve('.')
    s_ctx.bufInCwd = mPath.IsSamefile(s_ctx.cwd, s_ctx.bufDir)
enddef

def UpdateBufDir(): void
    s_ctx.bufDir = fnamemodify(expand('%'), ':p')
    if !mPath.IsDir(s_ctx.bufDir)
        s_ctx.bufDir = mPath.Parent(s_ctx.bufDir)
    endif
    s_ctx.bufInCwd = mPath.IsSamefile(s_ctx.cwd, s_ctx.bufDir)
enddef

UpdateCwd()
UpdateBufDir()

augroup VcAutoloadCmpUtilPath
    au!
    au DirChanged * UpdateCwd()
    au BufEnter * UpdateBufDir()
augroup END
### }}}
