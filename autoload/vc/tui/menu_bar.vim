vim9script

import autoload './core.vim'
import autoload './widget.vim' as mw
import autoload './layout.vim' as ml
import autoload './popup.vim' as mp
import autoload './menu.vim' as mm
import autoload './highlight.vim' as vhl
import autoload './window.vim'

type Widget = mw.Widget
type VisibleWidget = mw.VisibleWidget
type Align = mw.Align
type HBox = ml.HBox
type Menu = mm.Menu

const kDefZindex = 1000
const kDeltaZindex = 10
const kActionCloseAll = -1

const kCbMenu = 0
const kCbColOff = 1

class MenuBar extends HBox implements VisibleWidget
    var winid: number = -1
    var zindex: number = kDefZindex
    var _curIndex: number = 0
    var _size: number = 0
    var _cbs: list<tuple<Menu, number>> = []
    var _subMenuColOffset: list<number> = []
    var _keymap = core.Keymap(true)

    def new(a_items: list<Menu>)
        var index = 0
        var colOff = 0

        for item in a_items
            var tmp = item.section

            tmp.SetId(index)
            tmp.Render()
            tmp.SetWidth(tmp.dispWidth + 4)

            this.AddWidget(tmp)
            if tmp.key != null
                this._keymap[tolower(tmp.key)] = $'ACCEPT:{index}'
            endif
            this._cbs->add((item, colOff))
            item.SetParent(this)

            index += 1
            colOff += tmp.width
        endfor
        this._size = index

        this._PrepareHl()
        this.SetAlign(Align.Left)
        this.SetWidth(&columns)
        this.Render()

        var opts: dict<any> = {
            zindex: this.zindex,
            drag: 0,
            wrap: 0,
            border: [ 0, 0, 0, 0 ],
            padding: [ 0, 0, 0, 0 ],
            filter: this._Filter,
            callback: this._Callback,
            cursorline: 0,
            hidden: 1,
        }

        opts = opts->extend(mp.CalSize(this.image, {
            minwidth: 4,
        }))

        this.winid = popup_create(this.image, opts)
    enddef

    def OpenSubMenu(id: number): void
        var cb = this._cbs[id]
        var zindex = this.zindex + kDeltaZindex
        var menu = <Menu>cb[kCbMenu]
        menu.Open()
        popup_setoptions(menu.winid, { zindex: zindex })
        mp.Move(menu.winid, 2, cb[kCbColOff] + 1)
    enddef

    def CloseSubMenu(id: number): void
        var menu = this.widgets[id]
        menu.Close()
    enddef

    def _Filter(winid: number, a_key: string): bool
        const keymap = this._keymap
        if a_key == "\<esc>" || a_key == "\<C-c>"
            popup_close(winid, kActionCloseAll)
            return 1
        else
            var key = keymap->get(a_key, a_key)
            if key == 'ENTER' || key == 'DOWN'
                this.OpenSubMenu(this._curIndex)
            elseif key == 'LEFT'
                this._curIndex = max([0, this._curIndex - 1])
                this.Render()
            elseif key == 'RIGHT'
                this._curIndex = min([this._size - 1, this._curIndex + 1])
                this.Render()
            elseif key =~ '^ACCEPT:'
                var index = str2nr(key[7 :])
                this._curIndex = index
                this.Render()
                this.OpenSubMenu(this._curIndex)
            endif
            return 1
        endif
    enddef

    def _PrepareHl(): void
        vhl.Clear('VcKeyNoSel')
        vhl.Clear('VcKeySel')

        vhl.Extend('VcKeyNoSel', 'VcKey')
        vhl.Extend('VcKeySel', 'VcSel', 'bold')
    enddef

    def Render(): void
        super.Render()
        var cmds: list<string> = [ vhl.ClearCmd() ]
        for [k, v] in this.colors->items()
            for r in v
                var row = str2nr(k) + 1
                var c: string
                if r->len() < 4  # padding
                    c = r[2] == 'VcFcPadding' ? 'VcNormal' : 'VcNormal'
                else
                    if r[3] == this._curIndex
                        c = r[2] == 'VcFcKey' ? 'VcKeySel' : 'VcSel'
                    else
                        c = r[2] == 'VcFcKey' ? 'VcKeyNoSel' : 'VcNormal'
                    endif
                endif
                cmds->add(vhl.RegionCmd(c, row, r[0] + 1, row, r[1] + 1))
            endfor
        endfor
        mp.Resize(this.winid, max([this.width, this.dispWidth]), 1)
        window.Exec(this.winid, cmds)
    enddef

    def _Callback(winid: number, index: number): void
    enddef

    def Open(): void
        this.Render()
        mp.Move(this.winid, 1, 1)
        popup_setoptions(this.winid, { zindex: this.zindex })
        popup_show(this.winid)
    enddef

    def Close(): void
        popup_hide(this.winid)
    enddef
endclass


var s_menuBar: dict<MenuBar> = null_dict
var s_current: string = 'main'

def Register(a_entrys: list<Menu>, name: string = 'main'): void
    s_menuBar[name] = MenuBar.new(a_entrys)
enddef

def Unregister(name: string): void
    if !s_menuBar->has_key(name)
        throw $'no "{name}" registered'
    endif
    s_menuBar->remove(name)
enddef

def Switch(name: string): void
    if !s_menuBar->has_key(name)
        throw $'no "{name}" registered'
    endif
    s_current = name
enddef

def Open(a_name: string = null_string): void
    var name: string = a_name == null ? s_current : a_name
    if !s_menuBar->has_key(name)
        throw $'no "{name}" registered'
    endif
    s_menuBar[name].Open()
enddef

# test suit {{{ #
if 0
    def Test(): void
        var m1 = Menu.new('Test&1',  [
            ['&Hello', 'echo "hello"', 'Tip 1'],
            '--',
            ['&World', () => {
                execute 'echo "World"'
            }, 'Tip 2'],
        ])
        var m2 = Menu.new('Test&2', [
            ['&Red', 'echo "red"', 'This is red'],
        ])

        Register([m1, m2])
        Open()
    enddef

    Test()
endif
# }}} test suit #
