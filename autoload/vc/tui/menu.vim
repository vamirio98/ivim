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
    public var lv: number

    var _vertical: bool = true
    var _winid: number = -1
    var _visable: bool = false
    var _entries: list<any> = []
    var _keymap: dict<string> = null_dict

    # {a_entries} list of any, each entry can be string, list, Unit or Menu
    # string: treated as separater
    # list: only use as simple entry, use as `Unit`, [what, hook, help]
    # Unit: a simple entry
    # Menu: a sub-menu
    def new(a_name: string, a_entries: list<any>, this.help = v:none,
            a_opts: dict<any> = {})
        var name = Unit.new(a_name)
        this.name = name.text
        this.key = name.key

        this._vertical = a_opts->get('vertical', true)
        this._keymap = core.Keymap(true)

        var index = 0
        for entry in a_entries
            var t = type(entry)
            if t == v:t_string
                if entry == '---'  # separater
                    this._entries->add('---')
                else
                    var item = Unit.new(entry)
                    var key = item.key
                    this._entries->add(item)
                endif
            elseif t == v:t_list  # Unit item
                var item = Unit.new(entry)
                var key = item.key
                this._entries->add(item)
            elseif entry->instanceof(Unit)
                this._entries->add(entry)
            elseif entry->instanceof(Menu)
                this._entries->add(entry)
            else
                throw $'unsupport type'
            endif

            index += 1
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
            cursorline: 1,
            # hidden: 1,
        }
        opts = opts->extend(a_opts)

        var maxWidth = 4
        for entry in this._entries
            if type(entry) == v:t_string
                continue
            endif
            maxWidth = max([maxWidth, entry.width])
        endfor
        var content: list<string> = []
        for entry in this._entries
            if type(entry) == v:t_string
                content->add('-'->repeat(maxWidth))
            endif
            content->add(entry.text)
        endfor

        opts = opts->extend(window.CalSize(content, {
            minwidth: 4,
            maxwidth: maxWidth
        }))
        # opts = window.CalSize(content, opts)
        this._winid = popup_create(content, opts)
    enddef

    def _Filter(winid: number, a_key: string): bool
        const keymap = this._keymap
        if a_key == "\<esc>" || a_key == "\<C-c>"
            popup_close(winid, -1)
        elseif keymap->has_key(a_key)
            var key = keymap[a_key]
            if key == 'ENTER'
                popup_close(winid, line('.', winid))
                return true
            else
                window.MoveCursor(winid, key)
                redraw
                window.UpdateCursor(winid)
                return true
            endif
        endif
        return false
    enddef

    def _Callback(winid: number, result: any): void
        echo result
    enddef

    def Render(): void
    enddef

    def Show(): void
        this._vertical = true
        popup_show(this._winid)
    enddef

    def Hide(): void
        this._vertical = false
        popup_hide(this._winid)
    enddef
endclass

def Open(a_entrys: list<any>, a_opts: dict<any> = {}): void
enddef

var s_menuBar: dict<Menu> = null_dict

def RegisterMenuBar(a_entrys: list<any>, name: string = 'main'): void
    # s_menuBar[name] = Menu.new(a_entrys)
enddef

def SwitchMenuBar(name: string): void
enddef

def OpenMenuBar(): void
enddef

# Test suit {{{ #
if 1
    def Test(): void
        def Cb(winid: number, result: any): void
            echo $'w: {winid}, r: {result}'
        enddef

        var menu = Menu.new('test', ['red', 'green', 'blue'])
        menu.Show()

        # popup_menu(['red', 'green', 'blue'], { 'callback': Cb })
    enddef

    Test()
endif
# }}} Test suit #
