vim9script

import autoload './core.vim'
import autoload './unit.vim'
import autoload './window.vim'
import autoload './highlight.vim' as vhl
import autoload '../util/interact.vim'
import autoload '../util/string.vim' as str
import autoload './widget.vim' as mw
import autoload './layout.vim' as ml


type Unit = unit.Unit
type Widget = mw.Widget
type StaticWidget = mw.StaticWidget
type Align = mw.Align
type Layout = ml.Layout
type HBox = ml.HBox
type VBox = ml.VBox


class BtnLine extends HBox
    static const kMinBtnWidth = 6

    def new(parent: Layout, choices: string)
        this.parent = parent
        this.align = Align.Right

        var i = 1
        for ch in str.List(choices)
            var btn = Unit.new($'<{ch}>')
            btn.SetAlign(Align.Center)
            btn.SetId(i)
            btn.SetWidth(btn.dispWidth + 2)
            this.AddWidget(btn)
            i += 1
        endfor
    enddef
endclass


class Dialog extends VBox
    var _winid: number = -1
    var _btns: BtnLine = null_object
    var _quit: bool = false
    var _keymap: dict<string> = null_dict
    var _curIndex: number = 0

    # {question} should be string | list<string>
    def new(question: any, choices: string = "&Yes\n&No\n&Cancel",
            default: number = 1, title: string = 'Confirm')
        this.width = 10

        var opts: dict<any> = {
            title: $' {title} ',
        }

        var quesWidget = StaticWidget.new(this)
        quesWidget.SetImage((str.List(question) + [''])->mw.FillImage())
        quesWidget.SetAlign(Align.Left)
        this.AddWidget(quesWidget)

        this._btns = BtnLine.new(this, choices)
        this.AddWidget(this._btns)
        var maxWidth = max([quesWidget.dispWidth, this._btns.dispWidth])
        quesWidget.SetWidth(maxWidth)
        this._btns.SetWidth(maxWidth)

        this.Render()

        this._keymap = core.Keymap(true)
        for b in this._btns.widgets
            var btn = <Unit>b
            if btn.key != null
                this._keymap[tolower(btn.key)] = $'ACCEPT:{btn.id}'
            endif
        endfor

        this._curIndex = default
        opts = this._InitPopupOpts(this.image, opts)
        this._winid = popup_create(this.image, opts)

        this._PrepareHl()
    enddef


    def _Callback(winid: number, result: any): void
        this._quit = true
    enddef


    def _InitPopupOpts(what: list<string>, opts: dict<any>): dict<any>
        var popupOpts: dict<any> = opts->deepcopy()

        popupOpts->extend(window.CalSize(what, {
            minwidth: this.width,
            maxwidth: &columns * 80 / 100,
        }))
        popupOpts->extend({
            wrap: 0,
            cursorline: 0,
            drag: 0,
            close: 'button',
            border: [ 1, 1, 1, 1 ],
            borderchars: g:vcTuiBorderChars,
            padding: [ 0, 0, 0, 0 ],
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
        super.Render()
        var cmds: list<string> = [vhl.ClearCmd()]
        for [k, v] in this.colors->items()
            for r in v
                var row = str2nr(k) + 1
                var c: string
                if r[3] == this._curIndex
                    c = r[2] == 'Key' ? 'VcKeySel' : 'VcSel'
                else
                    c = r[2] == 'Key' ? 'VcKeyNoSel' : 'VcNormal'
                endif
                cmds->add(vhl.RegionCmd(c, row, r[0] + 1, row, r[1] + 1))
            endfor
        endfor
        window.Exec(this._winid, cmds)
    enddef

    def Exec(): number
        var accept = 0
        const size = this._btns.widgets->len()
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
                accept = this._curIndex
                break
            else
                var key = this._keymap->get(ch, ch)
                if key =~ '^ACCEPT:'
                    key = key->strpart(7)
                    accept = str2nr(key)
                    break
                elseif key == 'LEFT'
                    if this._curIndex > 1
                        this._curIndex -= 1
                    endif
                elseif key == 'RIGHT'
                    if this._curIndex < size
                        this._curIndex += 1
                    endif
                elseif key == 'HOME' || key == 'UP' || key == 'PAGEUP'
                    this._curIndex = 1
                elseif key == 'END' || key == 'DOWN' || key == 'PAGEDOWN'
                    this._curIndex = size
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
