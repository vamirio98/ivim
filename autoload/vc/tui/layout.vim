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

    # NOTE: each color list will append a widget's `id` to identify it
    def Render(): void
        if !this.dirty
            return
        endif

        # first, call all sub-widgets' Render() to update image
        var maxWidth = 0
        var totalHeight = 0
        for w in this.widgets
            w.Render()
            maxWidth = max([maxWidth, w.dispWidth])
            totalHeight += w.dispHeight
        endfor

        # sencond, render
        var row = 0
        var image: list<string> = []
        var colors: dict<list<list<any>>> = {}

        for w in this.widgets
            var [wImg, wColors] = mw.Compose(w, { width: maxWidth })
            image += wImg
            var tmpColors: dict<list<list<any>>> =
                mw.MoveColors(wColors, { rOff: row })
            for [k, v] in tmpColors->items()
                if colors->has_key(k)
                    colors[k] += v->map((_, value) => value->add(w.id))
                else
                    colors[k] = v->map((_, value) => value->add(w.id))
                endif
            endfor
            row += w.dispHeight
        endfor
        this.image = image
        this.colors = colors

        [this.image, this.colors] = mw.Compose(this, {
            width: max([this.width, maxWidth]),
            height: max([this.height, totalHeight])
        })
        this.dispHeight = this.image->len()
        this.dispWidth = this.dispHeight == 0 ?
            0 : this.image[0]->strdisplaywidth()

        this.dirty = false
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

    # NOTE: each color list will append a widget's `id` to identify it
    def Render(): void
        if !this.dirty
            return
        endif

        # first, call all sub-widgets' Render() to update image
        var totalWidth = 0
        var maxHeight = this.height
        for w in this.widgets
            w.Render()
            maxHeight = max([maxHeight, w.dispHeight])
            totalWidth += w.dispWidth
        endfor

        # sencond, render
        var col = 0
        var image: list<string> = ['']->repeat(maxHeight)
        var colors: dict<list<list<any>>> = {}

        for w in this.widgets
            var [wImg, wColors] = mw.Compose(w, { height: maxHeight })
            for i in wImg->len()->range()
                image[i] ..= wImg[i]
            endfor

            var tmpColors: dict<list<list<any>>> =
                mw.MoveColors(wColors, { cOff: col })
            for [k, v] in tmpColors->items()
                if colors->has_key(k)
                    colors[k] += v->map((_, value) => value->add(w.id))
                else
                    colors[k] = v->map((_, value) => value->add(w.id))
                endif
            endfor
            col += w.dispWidth
        endfor
        this.image = image
        this.colors = colors

        [this.image, this.colors] = mw.Compose(this, {
            width: max([this.width, totalWidth]),
            height: max([this.height, maxHeight])
        })
        this.dispHeight = this.image->len()
        this.dispWidth = this.dispHeight == 0 ?
            0 : this.image[0]->strdisplaywidth()

        this.dirty = false
    enddef
endclass

# Test VBox and HBox in comfirm.vim
