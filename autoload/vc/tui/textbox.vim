vim9script

import autoload './util.vim'
import autoload '../util/interact.vim'


#---------------------------------------------------------------
# Return { 'minwidth', 'maxwidth', 'minheight', 'maxheight' }
#---------------------------------------------------------------
def CalSize(what: any, opts: dict<any>): dict<number>
    var minWidth: number = opts->get('minwidth', 20)
    var minHeight: number = opts->get('minheight', 1)
    minWidth = max([minWidth, 20])
    minHeight = max([minHeight, 1])

    var maxWidth: number = (&columns * 0.8)->float2nr()
    var maxHeight: number = (&lines * 0.7)->float2nr()
    maxWidth = opts->get('maxwidth', maxWidth)
    maxHeight = opts->get('maxheight', maxHeight)

    var w: number = opts->get('w', 0)
    var h: number = opts->get('h', 0)
    # Auto calculate the width and height from `what`
    if w == 0 || h == 0
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
    var res: dict<number> = {
        'minwidth': w,
        'maxwidth': w,
        'minheight': h,
        'maxheight': h,
    }
    return res
enddef


def TrOpts(what: any, options: dict<any>): dict<any>
    var opts: dict<any> = options->deepcopy()

    opts->extend({
        'warp': 1,
        'cursorline': 1,
        'drag': 1,
        'close': 'button',
    }, 'keep')
    opts->extend(CalSize(what, options))
    opts->extend({
        'border': [ 1, 1, 1, 1 ],
        'borderchars': g:vcTuiBorderChars,
        'padding': [ 0, 1, 0, 1 ],
    }, 'keep')
    if opts->has_key('title')
        opts['title'] = $' {opts['title']} '
    endif
    opts->extend({ 'mapping': false, 'filter': Filter }, 'keep')

    return opts
enddef


def Filter(winid: number, key: string): bool
    var obj = util.Object()
    if !obj->has_key('keymap')
        obj.keymap = util.Keymap(true)
    endif
    const keymap = obj.keymap
    if key == "\<esc>" || key == "\<cr>" || key == "\<C-c>" ||
            key == " " || key == "x" || key == "q"
        popup_close(winid, line('.', winid))
        return true
    elseif key == '/' || key == '?' || key == ':'
        util.SearchOrJump(winid, key)
        redraw
        return true
    elseif keymap->has_key(key)
        const k = keymap[key]
        if k == 'ENTER' || k == 'ESC'
            popup_close(winid, line('.', winid))
            return true
        elseif k == 'NEXT' || k == 'PREV'
            util.SearchNext(winid, k == 'NEXT')
            return true
        else
            util.MoveCursor(winid, k)
            util.UpdateCursor(winid)
            return true
        endif
    endif
    return false
enddef


#---------------------------------------------------------------
# Open({what} [, {options}])
# Open a text box
#
# {what}: some as `popup_create`
# {options}: some as `popup_create` but also `w` and `h`
# NOTE: `options.callback` has the prototype like
# `F(winid: number, curline: number)`
#
# return the buffer id of the popup
#---------------------------------------------------------------
export def Open(what: any, options: dict<any> = null_dict): number
    var opts: dict<any> = TrOpts(what, options)
    var wnr: number = popup_create(what, opts)
    return wnr
enddef


#===============================================================
# Testing suit.
#===============================================================
if 0
    def T(winid: number, line: number): void
        echo util.GetWinBufOneLine(winid, line)
    enddef
    Open(bufnr('%'), { title: 'test', callback: T })
endif
