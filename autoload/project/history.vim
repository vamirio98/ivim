vim9script

import autoload 'util/path.vim' as mPath
import autoload 'util/file.vim' as mFile
import autoload 'util/msg.vim' as mMsg


# history format:
#   <name> | <session path>

def HistoryFile(): string
    return mPath.Joinpath(g:vcDataDir, 'project', 'history.txt')
enddef


if !mPath.IsDir(mPath.Parent(HistoryFile()))
    mkdir(mPath.Parent(HistoryFile()), 'p')
endif


# format:
#   [name, session path]
export def Get(): list<list<string>>
    var projs: list<list<string>> = []
    var fpath = HistoryFile()
    if !mPath.IsFile(fpath)
        return []
    endif
    var body: list<string> = readfile(fpath)
    for line in body
        projs->add(line->split(' | ', 1))
    endfor
    return projs
enddef


# add a new history
export def Update(newRecord: list<string>): void
    var hist: list<list<string>> = Get()
    hist->filter((_, val) => val[1] != newRecord[1])
    hist->insert(newRecord)
    var body: list<string> = hist->mapnew((_, val) => val->join(' | '))
    var err: string = mFile.SafeHandle(HistoryFile(),
        (fpath: string) => {
            writefile(body, fpath)
        })
    if !empty(err)
        mMsg.Error(err)
    endif
enddef


# clear all history
export def Clear(): void
    var err: string = mFile.SafeHandle(HistoryFile(),
        (fpath) => {
            writefile([], fpath)
        })
    if !empty(err)
        mMsg.Error(err)
    endif
enddef


# purge invalid project
export def Purge(): void
    var hist = Get()
    hist->filter((_, val) => mPath.Exists(val[1]))
    var body: list<string> = hist->mapnew((_, val) => val->join(' | '))
    var err = mFile.SafeHandle(HistoryFile(),
        (fpath) => {
            writefile(body, fpath)
        })
    if !empty(err)
        mMsg.Error(err)
    endif
enddef
