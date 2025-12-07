vim9script

import autoload './notify.vim'
import autoload './path.vim'

var msgQueue = []

g:vc_cache_dir = get(g:, 'vc_cache_dir', expand('~/.cache/vim'))
g:vc_log_dir = get(g:, 'vc_log_file', g:vc_cache_dir .. '/vc-log')
g:vc_log_keep_time = get(g:, 'vc_log_keep_time', 30)

var logPath: string = null_string

def Init(): void
    # Ensure the log directory exists
    if !isdirectory(g:vc_log_dir)
        if !exists('*mkdir')
            throw $'{g:vc_log_dir} does not exist'
        endif
        if !mkdir(g:vc_log_dir, 'p')
            throw $'can not create {g:vc_log_dir}'
        endif
    endif

    var today: string = strftime('%y-%m-%d')
    logPath = path.Join(g:vc_log_dir, $'{today}.log')->path.Abspath()

    # Clean up log older than `g:vc_log_keep_time`
    var curTime: number = localtime()
    var interval: number = g:vc_log_keep_time * 24 * 60 * 60
    for f in glob(path.Abspath(g:vc_log_dir) .. path.sep .. '*', true, true)
        if curTime - getftime(f) >= interval
            if delete(f) != 0
                notify.Error($'can not remove {f}')
            else
                notify.Warn($'remove {f}')
            endif
        endif
    endfor
enddef

Init()


enum LogLv
    Debug,
    Info,
    Warn,
    Error
endenum

var logLv: LogLv = LogLv.Info

export def GetLogLv(): LogLv
    return logLv
enddef

export def SetLogLv(lv: LogLv): void
    logLv = lv
enddef

def Log(lv: LogLv, what: any, flush: bool): void
    if lv.ordinal < logLv.ordinal
        return
    endif
    var msg: string = type(what) == v:t_list ? join(what, '\n') : what
    if exists('*strftime')
        msg = $'[{strftime("%y-%m-%d %H:%M:%S")}] {msg}'
    endif
    [msg]->writefile(logPath, 'a' .. (flush ? 's' : 'S'))
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
