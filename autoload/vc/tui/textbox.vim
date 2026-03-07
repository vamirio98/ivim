vim9script

import autoload './core.vim'
import autoload './util.vim'
import autoload './window.vim'


def Filter(winid: number, key: string): bool
    var obj = core.ObjAcquire(winid)
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


# {args} is the line number when close popup window
def Callback(winid: number, lnum: number): void
    var obj = core.ObjAcquire(winid)
    if obj->has_key('callback')
        obj.callback(winid, lnum)
    endif
    core.ObjRelease(winid)
enddef

def InitPopupOpts(what: any, options: dict<any>): dict<any>
    var opts: dict<any> = options == null ? options->deepcopy() : {}

    opts->extend(window.CalSize(what, opts))
    opts->extend({
        border: [ 1, 1, 1, 1 ],
        borderchars: g:vcTuiBorderChars,
        padding: [ 0, 1, 0, 1 ],
        wrap: 1,
        cursorline: 1,
        drag: 1,
        close: 'button',
        filter: Filter,
        callback: Callback,
        mapping: false,
    })

    opts['title'] = $' {get(opts, 'title', "Textbox")} '

    return opts
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
export def Open(what: any, opts: dict<any> = null_dict): number
    var popupOpts: dict<any> = InitPopupOpts(what, opts)
    var winid: number = popup_create(what, popupOpts)
    if opts->has_key('callback')
        var obj = core.ObjAcquire(winid)
        obj.callback = opts.callback
    endif
    return winid
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
