vim9script

import autoload './util.vim' as mUtil
import autoload './widget.vim' as mWidget
import autoload './button.vim' as mButton
import autoload './highlight.vim' as mHighlight
import autoload 'util/str.vim' as mStr
import autoload 'util/msg.vim' as mMsg

type Button = mButton.Button

def PrepareHighlight(bnr: number): void
    prop_type_add('VcTuiKey',
        { bufnr: bnr, highlight: 'VcTuiKey', priority: 101 })
    prop_type_add('VcTuiSel',
        { bufnr: bnr, highlight: 'VcTuiSel', priority: 100 })
enddef


# return: (image, highlightPos)
# highlightPos: [(row, startCol, length, keyCol)]
def BuildImage(a_text: list<string>,
        a_btns: list<Button>): tuple<list<string>, list<list<number>>>

    var image: list<string> = []
    var highlightPos: list<list<number>> = []
    image->extend(a_text)
    image->add('')

    var row = len(image) + 1
    var line: string = '    '
    var offset: number = len(line)
    for btn in a_btns
        var [text, key, keypos] = btn.Content()
        text = $'<{text}>'
        line = line .. $' {text}'
        var startCol = offset + 2
        if key == null
            highlightPos->add([row, startCol, len(text), -1])
        else
            var keyCol = startCol + (keypos + 1)
            highlightPos->add([row, startCol, len(text), keyCol])
        endif
        offset = len(line)
    endfor

    var maxW: number = 0
    for tmp in image
        maxW = max([maxW, mStr.DispLen(tmp)])
    endfor

    var ll = mStr.DispLen(line)
    if ll < maxW
        var nlpad = maxW - ll
        line = repeat(' ', nlpad) .. line
        for hp in highlightPos
            hp[1] += nlpad
            if hp[3] > 0
                hp[3] += nlpad
            endif
        endfor
    endif
    image->add(line)

    return (image, highlightPos)
enddef

export class Dialog extends mWidget.BasicWidget
    var btns: list<Button> = []
    var keymap: dict<string> = null_dict
    var running: bool = 1
    var choice: number = 0
    var highlightPos: list<list<number>> = []
    var _dirty: bool = true

    def new(a_text: list<string>, a_btns: list<string>, a_default: number = 1,
            a_title: string = null_string)
        for i in a_btns->len()->range()
            var tmp = Button.new([a_btns[i], () => {
                this.choice = i
                this.running = 0
                popup_close(this.win)
            }])
            this.btns->add(tmp)
        endfor

        this.keymap = mUtil.Keymap()
        var i = 1
        for btn in this.btns
            var [_, key, _] = btn.Content()
            if key != null
                this.keymap[key] = $'ACCEPT:{i}'
            endif
            btn.SetId(i)
            i += 1
        endfor

        this.choice = a_default

        var width: number = &columns * 40 / 100

        var opts = {
            maxwidth: width,
            maxheight: &lines * 40 / 100,
            wrap: 1,
            cursorline: 0,
            close: 'none',
            border: [ 1, 1, 1, 1 ],
            borderchars: g:vcTuiBorderChars,
            callback: this._Callback,
            hide: 1,
        }
        if a_title != null
            opts.title = a_title
        endif

        [this.image, this.highlightPos] = BuildImage(a_text, this.btns)

        this.win = popup_create(this.image, opts)
        this.buf = winbufnr(this.win)

        PrepareHighlight(this.buf)
    enddef

    def _Callback(win: number, result: any): void
        this.running = 0
        mHighlight.CursorShow()
    enddef

    def Render(first: bool = true): void
        if !this._dirty
            return
        endif

        prop_clear(1, line('$', this.win), { bufnr: this.buf })
        for i in this.btns->len()->range()
            var btn = this.btns[i]
            var hp = this.highlightPos[i]

            if this.choice == btn.id
                prop_add(hp[0], hp[1],
                    { type: 'VcTuiSel', length: hp[2], bufnr: this.buf })
            endif
            if hp[3] > 0
                prop_add(hp[0], hp[3],
                    { type: 'VcTuiKey', length: 1, bufnr: this.buf })
            endif
        endfor

        this._dirty = false
    enddef

    def Run(): number
        popup_show(this.win)
        var size = len(this.btns)

        this._dirty = true

        while this.running
            # NOTE: redraw! will flick the screen on windows, but without ! text
            # proprities changes may no been seen, setting 'renderoptions'
            # will improve it (only in gvim)
            if this._dirty
                this.Render()
                redraw!
            endif

            var ch: string
            try
                var c = getchar()
                ch = type(c) == v:t_string ? c : nr2char(c)
            catch /^Vim:Interrupt$/
                ch = 'ESC'
            catch
                mMsg.Error(v:exception)
                ch = 'ESC'
            endtry

            ch = this.keymap->get(ch, ch)
            if ch == 'ESC' || ch == "\<C-c>" || !this.running
                this.choice = 0
                break
            elseif ch == 'ENTER' || ch == "\<space>" || ch == "\<cr>"
                break
            else
                if ch =~ '^ACCEPT:'
                    ch = ch->strpart(7)
                    this.choice = str2nr(ch)
                    break
                elseif ch == 'LEFT' && this.choice > 1
                    this.choice -= 1
                    this._dirty = true
                elseif ch == 'RIGHT' && this.choice < size
                    this.choice += 1
                    this._dirty = true
                elseif this.choice != 1 &&
                        (ch == 'HOME' || ch == 'UP' || ch == 'PAGEUP')
                    this.choice = 1
                    this._dirty = true
                elseif this.choice != size &&
                        (ch == 'END' || ch == 'DOWN' || ch == 'PAGEDOWN')
                    this.choice = size
                    this._dirty = true
                endif
            endif
        endwhile

        popup_close(this.win)

        return this.choice
    enddef
endclass


export def Confirm(text: any, btns: list<string>,
        default: number = 1, title: string = null_string): number
    var dialog = Dialog.new(mStr.List(text), btns, default, title)
    return dialog.Run()
enddef


if 0
    echo Confirm('test confirm', ['&Yes', '&No', 'Cancel'], 1, 'test')
endif
