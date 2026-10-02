vim9script

import autoload 'util/path.vim' as mPath
import autoload 'util/file.vim' as mFile
import autoload 'util/msg.vim' as mMsg



# history format:
#   <name> | <session path>

if !mPath.IsDir(mPath.Parent(HistoryFile()))
    mkdir(mPath.Parent(HistoryFile()), 'p')
endif

def HistoryFile(): string
    return mPath.Joinpath(g:vcDataDir, 'project', 'history.txt')
enddef


# format:
#   [name, session path]
export def Get(): list<list<string>>
    var projs: list<list<any>> = []
    var fpath = HistoryFile()
    if !mPath.IsFile(fpath)
        return []
    endif
    var body: list<string> = readfile(fpath)
    for line in body
        projs->add(line->split(' | '))
    endfor
    return projs
enddef


# add a new history
export def Update(newRecord: list<string>): void
    var hist: list<list<string>> = Get()
    hist->filter((_, val) => val[1] != newRecord[1])
    hist->insert(newRecord)
    var err: string = mFile.SafeHandle(HistoryFile(),
        (fpath: string) => writefile(hist, fpath))
    mMsg.Error(err)
enddef


# clear all history
export def Clear(): void
    mMsg.Error(mFile.SafeHandle(HistoryFile(), (fpath) => writefile([], fpath)))
enddef


# purge invalid project
export def Purge(): void
    var hist = Get()
    hist->filter((_, val) => mPath.Exists(val))
    mMsg.Error(mFile.SafeHandle((fpath) => writefile(hist, fpath)))
enddef
