vim9script

import autoload './util.vim'
import autoload './window.vim'


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


# set the top left concer of the window
export def Move(winid: number, row: number, col: number): number
    popup_move(winid, { line: row, col: col })
    return winid
enddef


export def Resize(winid: number, w: number, h: number): number
    popup_move(winid, { minwidth: w, maxwidth: w, minheight: h, maxheight: h })
    return winid
enddef


export def SetTitle(winid: number, title: string): number
    popup_setoptions(winid, { title: title })
    return winid
enddef


# get popup's position, size and cursor position (whole window range)
# NOTE: column of cursor use characters index, no byte index
export def GetPos(winid: number): dict<number>
    var pr = popup_getpos(winid)
    return { row: pr.line, col: pr.col, width: pr.width, height: pr.height,
        coreRow: pr.core_line, coreCol: pr.core_col,
        coreWidth: pr.core_width, coreHeight: pr.core_height,
    }
enddef
