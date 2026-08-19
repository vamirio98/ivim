vim9script

import autoload './msg.vim' as mMsg
import autoload './path.vim' as mPath

var NewPath = mPath.New

g:vcCacheDir = get(g:, 'vcCacheDir', expand('~/.cache/vim/vc'))
g:vcLogDir = get(g:, 'vcLogFile', g:vcCacheDir .. '/log')
g:vcLogKeepDays = get(g:, 'vcLogKeepDays', 30)

var s_logPath: string = null_string

def Init(): void
    # Ensure the log directory exists
    if !isdirectory(g:vcLogDir)
        if !mkdir(g:vcLogDir, 'p')
            mMsg.Error($'can not create {g:vcLogDir}')
            return
        endif
    endif

    var today: string = strftime('%y-%m-%d')
    s_logPath = mPath.Joinpath(g:vcLogDir, $'{today}.log')->mPath.Resolve()

    # Clean up log older than `g:vcLogKeepDays`
    var curTime: number = localtime()
    var interval: number = g:vcLogKeepDays * 24 * 60 * 60
    var toRemove: list<string> = []
    for f in NewPath(g:vcLogDir).Resolve().Iterdir()
        if curTime - f.path->getftime() >= interval
            toRemove->add(f.path)
        endif
    endfor

    var RmOldLog: func = (_) => {
        for f in toRemove
            if delete(f) != 0
                mMsg.Error($'can not remove {f}')
            else
                mMsg.Warn($'remove {f}')
            endif
        endfor
    }
    if timer_start(2000, RmOldLog) < 0
        mMsg.Error('failed to use timer to delete old log')
        RmOldLog()
    endif
enddef

Init()


enum LogLv
    Debug,
    Info,
    Warn,
    Error
endenum

var s_logLv: LogLv = LogLv.Info

export def GetLogLv(): LogLv
    return s_logLv
enddef

export def SetLogLv(lv: LogLv): void
    s_logLv = lv
enddef

def Log(lv: LogLv, what: any, flush: bool): void
    if lv.ordinal < s_logLv.ordinal
        return
    endif
    var msg: string = type(what) == v:t_list ? join(what, '\n') : what
    if exists('*strftime')
        msg = printf('[%s] [%s] %s', strftime("%y-%m-%d %H:%M:%S"),
            lv.name[0], msg)
    endif
    [msg]->writefile(s_logPath, 'a' .. (flush ? 's' : 'S'))
enddef

export def Error(what: any, flush: bool = true): void
    Log(LogLv.Error, what, flush)
enddef

export def Warn(what: any, flush: bool = true): void
    Log(LogLv.Warn, what, flush)
enddef

export def Info(what: any, flush: bool = false): void
    Log(LogLv.Info, what, flush)
enddef

export def Debug(what: any, flush: bool = false): void
    Log(LogLv.Debug, what, flush)
enddef
