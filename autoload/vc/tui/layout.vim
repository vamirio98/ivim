vim9script

import autoload './widget.vim' as mw
import autoload './highlight.vim' as hl
import autoload './core.vim'

type Widget = mw.Widget
type BaseWidget = mw.BaseWidget

type Align = mw.Align
const kCenter = Align.Center
const kLeft = Align.Left
const kTop = Align.Top
const kRight = Align.Right
const kBottom = Align.Bottom
const kTopLeft = Align.TopLeft
const kTopRight = Align.TopRight
const kBotLeft = Align.BotLeft
const kBotRight = Align.BotRight

export interface Layout extends Widget
    var widgets: list<Widget>

    def AddWidget(a_widget: Widget): void

    # {a_item}: Widget or index of widget
    def DelWidget(a_item: any): void
endinterface


# x
# y
# z
export class VBox extends BaseWidget implements Layout
    # if parent is null, this is the top layout
    var widgets: list<Widget> = []

    def new(parent: Layout = null_object, opts: dict<any> = {})
        this.parent = parent
        this.width = opts->get('width', 640)
        this.height = opts->get('height', 480)
        this.align = opts->get('align', kCenter)
    enddef

    def AddWidget(a_widget: Widget): void
        this.widgets->add(a_widget)
        a_widget.SetParent(this)
        this.SetDirty()
    enddef

    def DelWidget(a_item: any): void
        if a_item->type() == v:t_number
            this.widgets->remove(a_item).SetParent(null_object)
        else
            for i in this.widgets->len()->range()
                if this.widgets[i] is a_item
                    this.widgets->remove(i).SetParent(null_object)
                endif
            endfor
        endif
        this.SetDirty()
    enddef

    def Render(): void
        if !this.dirty
            return
        endif

        # first, call all sub-widgets' Render() to update image
        var dispWidth = this.width
        var dispHeight = 0
        for w in this.widgets
            w.Render()
            dispWidth = max([dispWidth, w.dispWidth])
            dispHeight += w.dispHeight
        endfor
        dispHeight = max([dispHeight, this.height])

        this.dispWidth = dispWidth
        this.dispHeight = dispHeight

        # sencond, render
        var row = 0
        var image: list<string> = []
        var colors: dict<list<list<any>>> = {}

        for w in this.widgets
            var [wImg, wColors] = mw.Compose(w, { width: dispWidth })
            image += wImg
            var tmpColors: dict<list<list<any>>> =
                mw.MoveColors(wColors, { rOff: row })
            for [k, v] in tmpColors->items()
                if colors->has_key(k)
                    colors[k] += v
                else
                    colors[k] = v
                endif
            endfor
            row += w.dispHeight
        endfor

        this.dirty = false
        this.image = image
        this.colors = colors
    enddef
endclass


# x y z
export class HBox extends BaseWidget implements Layout
    # if parent is null, this is the top layout
    var widgets: list<Widget> = []

    def new(parent: Layout = null_object, opts: dict<any> = {})
        this.parent = parent
        this.width = opts->get('width', 640)
        this.height = opts->get('height', 480)
        this.align = opts->get('align', kCenter)
    enddef

    def AddWidget(a_widget: Widget): void
        this.widgets->add(a_widget)
        a_widget.SetParent(this)
        this.SetDirty()
    enddef

    def DelWidget(a_item: any): void
        if a_item->type() == v:t_number
            this.widgets->remove(a_item).SetParent(null_object)
        else
            for i in this.widgets->len()->range()
                if this.widgets[i] is a_item
                    this.widgets->remove(i).SetParent(null_object)
                endif
            endfor
        endif
        this.SetDirty()
    enddef

    def Render(): void
        if !this.dirty
            return
        endif

        # first, call all sub-widgets' Render() to update image
        var dispWidth = 0
        var dispHeight = this.height
        for w in this.widgets
            w.Render()
            dispHeight = max([dispHeight, w.dispHeight])
            dispWidth += w.dispWidth
        endfor
        dispWidth = max([dispWidth, this.width])

        this.dispWidth = dispWidth
        this.dispHeight = dispHeight

        # sencond, render
        var col = 0
        var image: list<string> = ['']->repeat(dispHeight)
        var colors: dict<list<list<any>>> = {}

        for w in this.widgets
            var [wImg, wColors] = mw.Compose(w, { height: dispHeight })
            for i in wImg->len()->range()
                image[i] ..= wImg[i]
            endfor

            var tmpColors: dict<list<list<any>>> =
                mw.MoveColors(wColors, { cOff: col })
            for [k, v] in tmpColors->items()
                if colors->has_key(k)
                    colors[k] += v
                else
                    colors[k] = v
                endif
            endfor
            col += w.dispWidth
        endfor

        this.dirty = false
        this.image = image
        this.colors = colors
    enddef
endclass

# Test VBox and HBox in comfirm.vim
