vim9script

import autoload '../util/interact.vim'
import autoload '../util/notify.vim'


export def ExtactBorderchars(border: string): list<string>
    if border->len() != 8
        throw $'{border} should include 8 characters'
    endif
    return border->split('\zs')
enddef


export def Exec(winid: number, command: any, silent: string = null_string): void
    var cmd: string = null_string
    if type(command) == v:t_string
        cmd = command
    elseif type(command) == v:t_list
        cmd = command->join("\n")
    endif
    keepalt win_execute(winid, cmd, silent)
enddef


# Options. {{{ #
#---------------------------------------------------------------
# Calculate window size according to {what} and {opts}
# Return { 'minwidth', 'maxwidth', 'minheight', 'maxheight' }
#---------------------------------------------------------------
export def CalSize(what: any = null, opts: dict<any> = null_dict): dict<any>
    var minWidth: number = opts->get('minwidth', 20)
    var minHeight: number = opts->get('minheight', 1)
    minWidth = max([minWidth, 4])
    minHeight = max([minHeight, 1])

    var maxWidth: number = (&columns * 0.8)->float2nr()
    var maxHeight: number = (&lines * 0.7)->float2nr()
    maxWidth = opts->get('maxwidth', maxWidth)
    maxHeight = opts->get('maxheight', maxHeight)

    var w: number = opts->get('w', 0)
    var h: number = opts->get('h', 0)
    # Auto calculate the width and height from `what`
    if (w == 0 || h == 0) && what != null
        var lines: list<string>
        if what->type() == v:t_list
            lines = what
        elseif what->type() == v:t_string
            lines = what->split("\n")
        else
            lines = what->getbufline(1, '$')
        endif

        if w == 0
            for line in lines
                w = max([w, line->strdisplaywidth()])
            endfor
        endif
        if h == 0
            h = lines->len()
        endif
    endif

    w = max([min([w, maxWidth]), minWidth])
    h = max([min([h, maxHeight]), minHeight])
    # Use dict<any> because other popup arguments may be any type
    var res: dict<any> = {
        'minwidth': w,
        'maxwidth': w,
        'minheight': h,
        'maxheight': h,
    }
    return res
enddef
# }}} Options. #


# Move and search. {{{ #
# NOTE: call `redraw` before call this function,
# otherwise the cursor may go to wrong position
# because Vim may get the old view info
export def UpdateCursor(winid: number): void
    const margin: number = &scrolloff
    var winHeight: number = winheight(winid)
    var winLine: number = ScreenLine(winid)
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
# Get the cursor position relative to the top row of the screen, one-based.
export def ScreenLine(winid: number): number
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
