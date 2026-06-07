vim9script

import autoload '../util/interact.vim'
import autoload '../util/notify.vim'


export def ExtactBorderchars(border: string): list<string>
    if border->len() != 8
        throw $'{border} should include 8 characters'
    endif
    return border->split('\zs')
enddef


export def Exec(winid: number, command: any, silent: string = null_string): string
    var cmd: string = null_string
    if type(command) == v:t_string
        cmd = command
    elseif type(command) == v:t_list
        cmd = command->join("\n")
    endif
    return win_execute(winid, cmd, silent)
    # keepalt win_execute(winid, cmd, silent)
enddef


# NOTE: column of buffer's cursor position in characters index, no byte index
export def SetCursor(winid: number, row: number = 1, col: number = 1): void
    Exec(winid, $'setcursorcharpos({row}, {col})')
enddef


# NOTE: column of buffer's cursor position in characters index, no byte index
export def GetCursor(winid: number): list<number>
    var cr = getcursorcharpos(winid)
    return [cr[1], cr[2]]
enddef


# NOTE: column of window's cursor position in characters index, no byte index
export def GetScreenPos(winid: number): list<number>
    var cur = getcurpos(winid)
    var pos = screenpos(winid, cur[1], cur[2])
    return [pos.row, pos.curscol]
enddef


# Move and search. {{{ #
# NOTE: call `redraw` before call this function,
# otherwise the cursor may go to wrong position
# because Vim may get the old view info
export def UpdateCursor(winid: number): void
    const margin: number = &scrolloff
    var winHeight: number = winheight(winid)
    var winLine: number = ScreenLineInWindow(winid)
    var line: number = line('.', winid)
    var lastLine: number = line('$', winid)
    var dBottom = winHeight - winLine
    var dTop = winLine - 1
    if dBottom < margin && dTop < margin
        return
    elseif dBottom < margin && lastLine - line >= margin
        Exec(winid, $"noautocmd normal {margin - dBottom}\<C-e>")
    elseif dTop < margin && dTop < line
        Exec(winid, $"noautocmd normal {margin - dTop}\<C-y>")
    endif
enddef

export def MoveCursor(winid: number, offset: string): void
    var winHeight: number = winheight(winid)
    var off: number = 0
    if offset == 'PAGEUP'
        off = -winHeight
    elseif offset == 'PAGEDOWN'
        off = winHeight
    elseif offset == 'HALFUP'
        off = -(winHeight / 2)
    elseif offset == 'HALFDOWN'
        off = winHeight / 2
    elseif offset == 'UP'
        off = -1
    elseif offset == 'DOWN'
        off = 1
    elseif offset == 'TOP'
        Exec(winid, 'noautocmd normal gg')
        return
    elseif offset == 'BOTTOM'
        Exec(winid, 'noautocmd normal G')
        return
    endif

    if off > 0
        Exec(winid, $"noautocmd normal {off}j")
    else
        Exec(winid, $"noautocmd normal {-off}k")
    endif
enddef


export def SearchOrJump(winid: number, cmd: string): void
    if cmd == '/' || cmd == '?'
        var text: string = interact.Input(cmd)
        # Exec(winid, 'set hlsearch')
        if text != null_string
            try
                # FIXME: ':' is required or E1050 will occur,
                # vim9script can not distinguish whether '/'
                # is search command or division sign
                Exec(winid, $':{cmd}{text}')
            catch /^Vim\%((\a\+)\)\=:E486:/
                notify.Error('E486: Pattern not found: ' .. text)
            endtry
            setwinvar(winid, '_vcTuiSearchCmd', cmd)
            setwinvar(winid, '_vcTuiSearchPattern', text)
        endif
    elseif cmd == ':'
        var text: string = interact.Input(cmd)
        if text != null_string
            Exec(winid, cmd .. text)
        endif
    endif
enddef


export def SearchNext(winid: number, forward: bool): void
    var prevCmd: string = getwinvar(winid, '_vcTuiSearchCmd')
    var prevPat: string = getwinvar(winid, '_vcTuiSearchPattern')
    if prevCmd == null_string || prevPat == null_string
        return
    endif

    var cmd: string = null_string
    if forward
        cmd = prevCmd
    else
        cmd = prevCmd == '/' ? '?' : '/'
    endif
    try
        # FIXME: ':' is required or E1050 will occur,
        # vim9script can not distinguish whether '/'
        # is search command or division sign
        Exec(winid, $':{cmd}{prevPat}')
    catch /^Vim\%((\a\+)\)\=:E486:/
        notify.Error($'E486: Pattern not found: {prevPat}')
    endtry
enddef
# }}} Move and search. #


# Misc. {{{ #
# Get the cursor position relative to the top row of the screen in
# specified window, one-based.
export def ScreenLineInWindow(winid: number): number
    # Also see :h getwininfo() for more infomation.
    var top: number = line('w0', winid)
    var cur: number = line('.', winid)
    return cur - top + 1
enddef


export def GetBufLine(winid: number, lnum: any, end: any = '$'): list<string>
    var bnr: number = winbufnr(winid)
    return getbufline(bnr, lnum, end)
enddef


export def GetBufOneLine(winid: number, lnum: any): string
    var bnr: number = winbufnr(winid)
    return getbufoneline(bnr, lnum)
enddef
# }}} Misc. #
