vim9script

import autoload './core.vim'
import autoload './unit.vim'
import autoload './util.vim'
import autoload './window.vim'
import autoload './highlight.vim' as vhl
import autoload '../util/interact.vim'


type Unit = unit.Unit


class Dialog
    var _btns: list<Unit> = null_list
    var _winid: number = -1
    var _info: dict<any> = null_dict
    var _quit: bool = false
    var _keymap: dict<string> = null_dict
    var _curIndex: number = -1

    # {content} should be string | list<string>
    def new(content: any, choices: string = "&Yes\n&No\n&Cancel",
            default: number = 1, title: string = 'Confirm')
        var opts: dict<any> = {
            title: $' {title} '
        }
        this._btns = this._GenButtons(choices)
        var btnLine = this._GenBtnLine(this._btns)
        var what = util.StrListNormalize(content) + ['', '', btnLine]
        this._keymap = core.Keymap(true)
        var index = 0
        for btn in this._btns
            var key = btn.key
            if key != null
                this._keymap[tolower(key.char)] = $'ACCEPT:{index}'
                index += 1
            endif
        endfor
        this._curIndex = default - 1
        opts = this._InitPopupOpts(what, opts)
        this._winid = popup_create(what, opts)
        this._info = popup_getpos(this._winid)
        this._PrepareHl()

        for btn in this._btns
            btn.pos.row = what->len()
        endfor
    enddef

    # Buttons. {{{ #
    def _GenButtons(choices: string): list<Unit>
        var btns: list<Unit> = []
        var chs = util.StrListNormalize(choices)
        var index = 0
        var maxWidth = 4

        for ch in chs
            var btn = Unit.new(ch)
            btn.index = index
            btns->add(btn)
            maxWidth = max([maxWidth, btn.width])
            index += 1
        endfor

        for btn in btns
            var width = btn.width
            var padLeft = (maxWidth - width) / 2
            var padRgiht = maxWidth - width - padLeft
            btn.text = $'{repeat(" ", padLeft)}{btn.text}{repeat(" ", padRgiht)}'
            btn.width = maxWidth
            # NOTE: btn.key.col += padLeft will cause error, strange
            var key = btn.key
            if key != null
                key.col += padLeft
            endif
        endfor

        return btns
    enddef


    # NOTE: will modify {btns}
    def _GenBtnLine(btns: list<Unit>): string
        var line = ''
        var hlStart = 1  # column is 1-base
        var index = len(btns) - 1
        for btn in btns
            var text = $'<{btn.text}>'
            btn.width += 2
            var key = btn.key
            if key != null
                key.col += 1
                key.col = hlStart + key.col
            endif
            btn.pos.col = hlStart
            hlStart += btn.width
            line ..= text
            if index > 0
                line ..= '  '
                hlStart += 2
            endif
            index -= 1
        endfor
        return line
    enddef
    # }}} Buttons. #


    def _Callback(winid: number, result: any): void
        this._quit = true
    enddef


    def _InitPopupOpts(what: any, opts: dict<any>): dict<any>
        var popupOpts: dict<any> = opts->deepcopy()

        popupOpts->extend(window.CalSize(what, {
            minWidth: 40,
            maxWidth: &columns * 80 / 100,
        }))
        popupOpts->extend({
            wrap: 0,
            cursorline: 0,
            drag: 0,
            close: 'button',
            border: [ 1, 1, 1, 1 ],
            borderchars: g:vcTuiBorderChars,
            padding: [ 1, 1, 1, 1 ],
            callback: this._Callback,
        })

        return popupOpts
    enddef


    def _PrepareHl(): void
        vhl.Clear('VcKeyNoSel')
        vhl.Clear('VcKeySel')

        vhl.Extend('VcKeyNoSel', 'VcKey')
        vhl.Extend('VcKeySel', 'VcSel', 'underline')
    enddef

    def Render(): void
        var cmds: list<string> = []
        cmds->add(core.HlClearCmd())

        for btn in this._btns
            var c1 = null_string
            var c2 = null_string
            if this._curIndex == btn.index
                c1 = 'VcSel'
                c2 = 'VcKeySel'
            else
                c1 = 'VcNormal'
                c2 = 'VcKeyNoSel'
            endif
            var row = btn.pos.row
            var col = btn.pos.col
            var key = btn.key
            if key != null
                cmds->add(core.HlRegionCmd(c1, row, col, row, key.col))
                col = key.col
                cmds->add(core.HlRegionCmd(c2, row, col, row, col + 1))
                col += 1
                cmds->add(core.HlRegionCmd(c1, row, col,
                    row, btn.pos.col + btn.width
                ))
            else
                cmds->add(core.HlRegionCmd(
                    c1,
                    row, col,
                    row, col + btn.width
                ))
            endif
        endfor

        for cmd in cmds
            window.Exec(this._winid, cmd)
        endfor
    enddef

    def Exec(): number
        var accept = 0
        const size = this._btns->len()
        while true
            this.Render()
            redraw

            var ch = interact.Getchar()
            # NOTE: popup will handle <C-c>, so it will freeze when press
            # <C-c> until other key press
            if ch == "\<C-c>" || ch == "\<Esc>" || this._quit
                accept = 0
                break
            elseif ch == "\<space>" || ch == "\<cr>"
                accept = this._curIndex + 1
                break
            else
                var key = this._keymap->get(ch, ch)
                if key =~ '^ACCEPT:'
                    key = key->strpart(7)
                    accept = str2nr(key) + 1
                    break
                elseif key == 'LEFT'
                    if this._curIndex > 0
                        this._curIndex -= 1
                    endif
                elseif key == 'RIGHT'
                    if this._curIndex < size - 1
                        this._curIndex += 1
                    endif
                elseif key == 'HOME' || key == 'UP' || key == 'PAGEUP'
                    this._curIndex = 0
                elseif key == 'END' || key == 'DOWN' || key == 'PAGEDOWN'
                    this._curIndex = size - 1
                endif
            endif
        endwhile

        popup_close(this._winid)

        return accept
    enddef
endclass

#---------------------------------------------------------------
# Open({question} [, {choices} [, {default} [, {title}]]])
# {choices}: e.g.: '&Yes\n&No\n&Cancel' will generate three
#                  choices with hot key:
#                  Yes(Y/y, return 1),
#                  No(N/n, return 2)
#                  and Cancel(C/c, return 3).
#                  If press <Esc> or <C-c>, 0 will return
#---------------------------------------------------------------
export def Open(question: string, choices: string = "&Yes\n&No\n&Cancel",
        default: number = 1, title: string = 'Confirm'): number
    var win: Dialog = Dialog.new(question, choices, default, title)
    return win.Exec()
enddef


#---------------------------------------------------------------
# Testing suit.
#---------------------------------------------------------------
if 0
    def Test(): void
        echo Open('Yes or no?')
    enddef

    Test()
endif
