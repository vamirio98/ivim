vim9script

import autoload './core.vim'
import autoload './unit.vim'
import autoload './window.vim'
import autoload './highlight.vim' as vhl
import autoload './widget.vim' as mw
import autoload './layout.vim' as ml

type Unit = unit.Unit
type Widget = mw.Widget
type Align = mw.Align
type VBox = ml.VBox

const kDefZindex: number = 1000  # default priority of the menu
const kDeltaZindex: number = 5

class Menu extends VBox
    var winid: number = -1
    var section: Unit = null_object
    var zindex: number = kDefZindex
    var visable: bool = false
    var active: bool = true

    var _size: number = 0
    var _curIndex: number = 0  # -1 means no select
    var _keymap: dict<string> = null_dict
    var _cbs: dict<func> = {}

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
        secDesc.cb = this.Open
        this.section = Unit.new(secDesc)
        this._keymap = core.Keymap(true)

        var index = 0
        var maxWidth = 0
        for item in a_items
            var tmp: Unit = null_object

            var t = item->type()
            if t == v:t_string || t == v:t_list || t == v:t_dict
                tmp = Unit.new(item)
            elseif item->instanceof(Unit)
                tmp = item
            elseif item->instanceof(Menu)
                tmp = item.section
            endif
            maxWidth = max([maxWidth, tmp.dispWidth])
            this.AddWidget(tmp)

            if tmp.isSep
                continue
            endif

            tmp.SetId(index)
            this._cbs[index] = tmp.Exec
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
        opts = opts->extend(window.CalSize(this.image, {
            minwidth: 4,
        }))
        this.winid = popup_create(this.image, opts)
    enddef

    def _Filter(winid: number, a_key: string): bool
        const keymap = this._keymap
        if a_key == "\<esc>" || a_key == "\<C-c>"
            popup_close(winid, -1)
            return 1
        else
            var key = keymap->get(a_key, a_key)
            if key == 'ENTER'
                popup_close(winid, this._curIndex)
                return 1
            elseif key =~ '^ACCEPT:'
                popup_close(winid, str2nr(key[7 :]))
                return 1
            else
                if key == 'DOWN'
                    this._curIndex += 1
                elseif key == 'UP'
                    this._curIndex -= 1
                endif
                this._curIndex = max([0, min([this._size - 1, this._curIndex])])
                this.Render()
                redraw
                return 1
            endif
        endif
    enddef

    def _Callback(winid: number, index: number): void
        if index < 0
            return
        endif
        var F = this._cbs[index]
        F()
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
        var prevIndex = 0
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

    def Open(): void
        this.visable = true
        this.Render()
        popup_setoptions(this.winid, { zindex: this.zindex })
        popup_show(this.winid)
    enddef

    def Close(): void
        this.visable = false
        popup_hide(this.winid)
    enddef
endclass

def Open(a_entries: list<any>, a_opts: dict<any> = {}): void
    var menu = Menu.new('', a_entries, a_opts)
    menu.Open()
enddef

# Test suit {{{ #
if 1
    def Test(): void
        var item = Unit.new({
            what: '&Green',
            cb: () => {
                execute 'echo "green"'
            },
            help: 'This is green'
        })
        var menu = Menu.new('sub-menu', [
            ['&Hello', 'echo "hello"', 'Tip 1'],
            '--',
            ['&World', () => {
                execute 'echo "World"'
            }, 'Tip 2'],
        ])

        Open([
            ['&Red', 'echo "red"', 'This is red'],
            item,
            '-',
            {what: '&Blue', cb: 'echo "blue"', help: 'This is blue'},
            menu,
        ])
    enddef

    Test()
endif
# }}} Test suit #
