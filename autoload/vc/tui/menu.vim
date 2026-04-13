vim9script

import autoload './core.vim'
import autoload './unit.vim'
import autoload './window.vim'

type Unit = unit.Unit
type Key = unit.Key

const s_zindex: number = 1000  # default priority of the menu

class Menu
    public var name: string = null_string
    public var help: string = null_string
    public var key: Key = null_object
    public var index: number = -1
    public var level: number

    var _curIndex: number = 0
    var _size: number = 0
    var _vertical: bool = true
    var _winid: number = -1
    var _visable: bool = false
    var _entries: list<any> = []
    var _keymap: dict<string> = null_dict

    # {a_entries} list of any, each entry can be param of Unit.new(), Unit
    # or Menu
    # param of Unit.new() or Unit: a simple entry
    # Menu: a sub-menu
    def new(a_name: string, a_entries: list<any>, this.help = v:none,
            a_opts: dict<any> = {})
        var name = Unit.new(a_name)
        this.name = name.text
        this.key = name.key

        this._vertical = a_opts->get('vertical', true)
        this._keymap = core.Keymap(true)
        this._size = 0

        for entry in a_entries
            var t = type(entry)
            if t == v:t_string || t == v:t_list || t == v:t_dict
                var item = Unit.new(entry)
                this._entries->add(item)
                if item.isSep
                    item.index = -1
                    continue
                endif
                item.index = this._size
            elseif entry->instanceof(Unit)
                this._entries->add(entry)
                entry.index = this._size
            elseif entry->instanceof(Menu)
                this._entries->add(entry)
                entry.index = this._size
            else
                throw $'unsupport type'
            endif

            this._size += 1
        endfor

        var opts: dict<any> = {
            zindex: 200,
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
        opts = opts->extend(a_opts)

        var image = this._BuildImage()
        opts = opts->extend(window.CalSize(image, {
            minwidth: 4,
        }))
        this._winid = popup_create(image, opts)
    enddef

    def _BuildImage(): list<string>
        var maxWidth = 4
        for entry in this._entries
            maxWidth = max([maxWidth, entry.width])
        endfor
        maxWidth += 2  # padding 1 space in left and right
        var image: list<string> = []
        for entry in this._entries
            if entry->instanceof(Unit)
                if entry.isSep
                    entry.text = repeat('─', maxWidth)
                else
                    entry.text = $' {entry.text}{repeat(" ", maxWidth - 1 - entry.width)}'
                endif
                entry.width = maxWidth
                image->add(entry.text)
            endif
        endfor
        return image
    enddef

    def _Filter(winid: number, a_key: string): bool
        const keymap = this._keymap
        if a_key == "\<esc>" || a_key == "\<C-c>"
            popup_close(winid, -1)
        elseif keymap->has_key(a_key)
            var key = keymap[a_key]
            if key == 'ENTER'
                popup_close(winid, this._curIndex + 1)
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
        this.Render()
        redraw
        return 0
    enddef

    def _Callback(winid: number, result: any): void
        echo result
    enddef

    def Render(): void
        var cmds: list<string> = [ core.HlClearCmd() ]
        var row = 1
        for entry in this._entries
            if entry.index == this._curIndex
                cmds->add(core.HlRegionCmd('VcSel', row, 1, row, entry.width + 1))
            else
                cmds->add(core.HlRegionCmd('VcNormal', row, 1, row, entry.width + 1))
            endif
            row += 1
        endfor
        window.Exec(this._winid, cmds)
    enddef

    def Show(): void
        this._vertical = true
        this.Render()
        popup_show(this._winid)
    enddef

    def Hide(): void
        this._vertical = false
        popup_hide(this._winid)
    enddef
endclass

def Open(a_entries: list<any>, a_opts: dict<any> = {}): void
    var menu = Menu.new('', a_entries, '', a_opts)
    menu.Show()
enddef

# Test suit {{{ #
if 1
    def Test(): void
        Open(['Red', 'Green', '---', 'Blue'])
    enddef

    Test()
endif
# }}} Test suit #
