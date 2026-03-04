vim9script

import autoload './util.vim'
import autoload './window.vim'
import autoload '../util/interact.vim'


def TrOpts(what: any, options: dict<any>): dict<any>
    var opts: dict<any> = options->deepcopy()

    opts->extend({
        'wrap': 1,
        'cursorline': 1,
        'drag': 1,
        'close': 'button',
    }, 'keep')
    opts->extend(window.CalSize(what, options))
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
        obj.keymap = window.Keymap(true)
    endif
    const keymap = obj.keymap
    if key == "\<esc>" || key == "\<cr>" || key == "\<C-c>" ||
            key == " " || key == "x" || key == "q"
        popup_close(winid, line('.', winid))
        return true
    elseif key == '/' || key == '?' || key == ':'
        window.SearchOrJump(winid, key)
        redraw
        window.UpdateCursor(winid)
        return true
    elseif keymap->has_key(key)
        const k = keymap[key]
        if k == 'ENTER' || k == 'ESC'
            popup_close(winid, line('.', winid))
            return true
        elseif k == 'NEXT' || k == 'PREV'
            window.SearchNext(winid, k == 'NEXT')
            redraw
            window.UpdateCursor(winid)
            return true
        else
            window.MoveCursor(winid, k)
            redraw
            window.UpdateCursor(winid)
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
        echo window.GetBufOneLine(winid, line)
    enddef
    Open(bufnr('%'), { title: 'test', callback: T })
endif
