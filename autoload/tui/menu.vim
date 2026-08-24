vim9script

# TODO: show help in popup

import autoload './core.vim'
import autoload './unit.vim'
import autoload './window.vim'
import autoload './highlight.vim' as vhl
import autoload './widget.vim' as mw
import autoload './layout.vim' as ml
import autoload './popup.vim' as mp
import autoload 'vc/util/notify.vim'

type Unit = unit.Unit
type Widget = mw.Widget
type VisibleWidget = mw.VisibleWidget
type Align = mw.Align
type VBox = ml.VBox

const kDefZindex: number = 1000  # default priority of the menu
const kDeltaZindex: number = 5
const kActionCloseAll = -1
const kActionCloseSelf = -2

# member index of _cbs
const kCbCallback = 0
const kCbRow = 1
const kCbIsSection = 2
const kCbWinid = 3

export class Menu extends VBox implements VisibleWidget
    var winid: number = -1
    var section: Unit = null_object
    var zindex: number = kDefZindex
    var visible: bool = false
    var active: bool = true

    var _size: number = 0
    var _curIndex: number = 0  # -1 means no select
    var _keymap: dict<string> = null_dict
    # callback, row, isSection, winid (kCbXXX)
    var _cbs: dict<tuple<func, number, bool, number>> = {}

    # {a_section}: like Unit.new.what, can be following type:
    #   string
    #   list: [what, help]
    #   dict: { what, help }
    # {a_items} list of any, each entry can be param of Unit.new(), Unit
    # or Menu
    #   param of Unit.new() or Unit: a simple entry
    #   Menu: a sub-menu
    # TODO: {a_opts} support filetype
    def new(a_section: any, a_items: list<any>, a_opts: dict<any> = {})
        var secDesc: dict<any> = {}
        var st = a_section->type()
        if st == v:t_string
            secDesc.what = a_section
        elseif st == v:t_list
            secDesc.what = a_section[0]
            secDesc.help = a_section->get(1, null_string)
        elseif st == v:t_dict
            secDesc = a_section->deepcopy()
        else
            throw $'unsupported type: {st}'
        endif
        secDesc.cb = this.OpenAsSubMenu
        this.section = Unit.new(secDesc)
        this.section.SetIsSection(true)
        this._keymap = core.Keymap(true)

        var index = 0
        var row = 0
        var maxWidth = 0
        for item in a_items
            row += 1
            var tmp: Unit = null_object

            var t = item->type()
            if t == v:t_string || t == v:t_list || t == v:t_dict
                tmp = Unit.new(item)
            elseif item->instanceof(Unit)
                tmp = item
            elseif item->instanceof(Menu)
                tmp = item.section
                item.SetParent(this)
            endif
            maxWidth = max([maxWidth, tmp.dispWidth])
            this.AddWidget(tmp)

            if tmp.isSep
                continue
            endif

            tmp.SetId(index)
            this._cbs[index] = (tmp.Exec, row, tmp.isSection,
                tmp.isSection ? item.winid : -1)
            if tmp.key != null
                this._keymap[tolower(tmp.key)] = $'ACCEPT:{index}'
            endif

            index += 1
        endfor
        this._size = index

        for w in this.widgets
            w.SetAlign(Align.Left)
            w.SetWidth(maxWidth)
            w.Render()
            w.SetAlign(Align.Center)
            w.SetWidth(maxWidth + 2)
            w.Render()
        endfor
        this.SetAlign(Align.Center)

        this._PrepareHl()
        this.Render()

        var opts: dict<any> = {
            zindex: this.zindex,
            drag: 0,
            wrap: 0,
            border: [ 1, 1, 1, 1 ],
            borderchars: g:vcTuiBorderChars,
            padding: [0, 0, 0, 0],
            mapping: 0,
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


    def _Filter(winid: number, a_key: string): bool
        const keymap = this._keymap
        if a_key == "\<CursorHold>"
            return 1
        elseif a_key == "\<esc>" || a_key == "\<C-c>"
            popup_close(winid, kActionCloseAll)
            return 1
        else
            var key = keymap->get(a_key, a_key)
            if key == 'ENTER' || key == 'RIGHT'
                var cb = this._cbs[this._curIndex]
                if cb[kCbIsSection]
                    var F = cb[kCbCallback]
                    F()
                else
                    popup_close(winid, this._curIndex)
                endif
                return 1
            elseif key == 'LEFT' || key == "\<bs>"
                if this.parent == null  # do not hide the top menu
                    return 1
                endif
                this._curIndex = 0
                popup_hide(winid)
                return 1
            elseif key =~ '^ACCEPT:'
                var index = str2nr(key[7 :])
                this._curIndex = index
                var cb = this._cbs[index]
                window.SetCursor(winid, cb[kCbRow], 1)
                if cb[kCbIsSection]
                    var F = cb[kCbCallback]
                    F()
                    this.Render()
                else
                    popup_close(winid, this._curIndex)
                endif
                return 1
            else
                if key == 'DOWN'
                    this._curIndex += 1
                elseif key == 'UP'
                    this._curIndex -= 1
                endif
                this._curIndex = max([0, min([this._size - 1, this._curIndex])])
                var cbs = this._cbs[this._curIndex]
                var row = cbs[kCbRow]
                var item = <Unit>this.widgets[row - 1]
                if item.help != null
                    notify.Info(item.help)
                else
                    notify.Clear()
                endif
                window.SetCursor(winid, row, 1)
                this.Render()
                redraw
                return 1
            endif
        endif
    enddef

    def _Callback(winid: number, index: number): void
        vhl.CursorShow()
        if index >= 0
            var F = this._cbs[index][kCbCallback]
            F()
        endif

        if index == kActionCloseAll || index >= 0
            if this.parent != null
                var parent = <VisibleWidget>this.parent
                popup_close(parent.winid, kActionCloseAll)
                this.parent = null_object
            endif
            # clear all sub-menu, avoid popup buffer leak
            for cb in this._cbs->values()
                if cb[kCbIsSection]
                    popup_close(cb[kCbWinid], kActionCloseSelf)
                endif
            endfor
            return
        elseif index == kActionCloseSelf
            return
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
                if r[3] == this._curIndex
                    c = r[2] == 'VcFcKey' ? 'VcKeySel' : 'VcSel'
                else
                    c = r[2] == 'VcFcKey' ? 'VcKeyNoSel' : 'VcNormal'
                endif
                cmds->add(vhl.RegionCmd(c, row, r[0] + 1, row, r[1] + 1))
            endfor
        endfor
        window.Exec(this.winid, cmds)
    enddef


    def SetZindex(zindex: number): void
        this.zindex = zindex
    enddef


    def OpenAsSubMenu(): void
        if this.parent == null || !this.parent->instanceof(Menu)
            return
        endif
        var parent = <Menu>this.parent
        var pwinid = parent.winid
        var pPos = mp.GetPos(pwinid)
        var cur = window.GetCursor(pwinid)
        var pos = mp.GetPos(this.winid)
        this.Open()
        this.SetZindex(parent.zindex + kDeltaZindex)
        popup_setoptions(this.winid, { zindex: this.zindex })
        this.winid->mp.Move(
            (pPos.coreRow + (cur[0] - 1)) - (pos.coreRow - pos.row),
            pPos.col + pPos.width)
    enddef


    def Open(): void
        this.visible = true
        this.Render()
        popup_setoptions(this.winid, { zindex: this.zindex })
        popup_show(this.winid)
        vhl.CursorHide()
    enddef

    def Close(): void
        this.visible = false
        popup_hide(this.winid)
        vhl.CursorShow()
    enddef
endclass

export def Open(a_entries: list<any>, a_opts: dict<any> = {}): void
    var menu = Menu.new('', a_entries, a_opts)
    menu.Open()
enddef

export def OpenAtCursor(a_entries: list<any>, a_opts: dict<any> = {}): void
    var menu = Menu.new('', a_entries, a_opts)
    var pos = window.GetScreenPos(win_getid())
    # column + 1 to avoid cursor
    mp.Move(menu.winid, pos[0], pos[1] + 1)
    menu.Open()
enddef

# Test suit {{{ #
if 0
    def Test(): void
        var item = Unit.new({
            what: '&Green',
            cb: () => {
                execute 'echo "green"'
            },
            help: 'This is green'
        })
        var menu = Menu.new('&sub-menu', [
            ['&Hello', 'echo "hello"', 'Tip 1'],
            '--',
            ['&World', () => {
                execute 'echo "World"'
            }, 'Tip 2'],
        ])

        var entries = [
            ['&Red', 'echo "red"', 'This is red'],
            item,
            '-',
            {what: '&Blue', cb: 'echo "blue"', help: 'This is blue'},
            menu,
        ]

        # Open(entries)
        OpenAtCursor(entries)
    enddef

    Test()
endif
# }}} Test suit #
