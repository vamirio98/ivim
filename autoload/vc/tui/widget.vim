vim9script

import autoload '../util/string.vim' as str

export enum Align
    Center,
    Left,
    Top,
    Right,
    Bottom,
    TopLeft,
    TopRight,
    BotLeft,
    BotRight
endenum

const kCenter = Align.Center
const kLeft = Align.Left
const kTop = Align.Top
const kRight = Align.Right
const kBottom = Align.Bottom
const kTopLeft = Align.TopLeft
const kTopRight = Align.TopRight
const kBotLeft = Align.BotLeft
const kBotRight = Align.BotRight

export interface PureWidget
    var image: list<string>
    var dispWidth: number
    var dispHeight: number
    # [ rowOff, [ [colOff1, colOff2, highlight] ] ]
    # NOTE: should contains above infomation at least
    # NOTE: region format: [colOff1, colOff2)
    var colors: dict<list<list<any>>>

    # NOTE: image should be a rect after Render()
    def Render(): void
endinterface

export interface Widget extends PureWidget
    var parent: Widget
    var align: Align
    # dispWidth/dispHeight is the actual size of the widget while
    # width/height is the setting size, if the content size is larger than
    # setting, dispWidth/dispHeight will grow to fit it, otherwise them
    # will be same as width/height
    var width: number
    var height: number

    def SetWidth(width: number): void
    def SetHeight(height: number): void
    def SetParent(parent: Widget): void
    def SetAlign(align: Align): void
    def SetDirty(dirty: bool): void
endinterface


export class BaseWidget implements Widget
    var image: list<string> = []
    var dispWidth: number = 0
    var dispHeight: number = 0
    var colors: dict<list<list<any>>> = {}

    var parent: Widget = null_object
    var align: Align = kCenter
    var width: number = 0
    var height: number = 0

    var dirty: bool = true

    def Render(): void
    enddef

    def SetWidth(width: number): void
        this.width = width
        this.SetDirty(true)
    enddef

    def SetHeight(height: number): void
        this.height = height
        this.SetDirty(true)
    enddef

    def SetParent(parent: Widget): void
        this.parent = parent
        this.SetDirty(true)
    enddef

    def SetAlign(align: Align): void
        this.align = align
        this.SetDirty(true)
    enddef

    def SetDirty(dirty: bool = true): void
        this.dirty = dirty
        if this.parent != null
            this.parent.SetDirty(true)
        endif
    enddef
endclass


export class StaticWidget extends BaseWidget
    def new(parent: Widget = null_object)
        this.parent = parent
    enddef

    def SetImage(image: any): void
        this.image = str.List(image)
        this.SetDirty(true)
    enddef

    def SetColors(colors: dict<list<list<any>>>): void
        this.colors = colors->deepcopy()
        this.SetDirty(true)
    enddef

    def Render(): void
        [this.image, this.colors] = Compose(this)
        this.dispHeight = this.image->len()
        this.dispWidth = this.dispHeight == 0 ? 0 : this.image[0]->len()
    enddef
endclass


# add space at the end of line to make image a rect
export def FillImage(a_image: list<string>): list<string>
    var image: list<string> = []
    var maxWidth = 0

    for line in a_image
        maxWidth = max([maxWidth, strdisplaywidth(line)])
    endfor
    for line in a_image
        image->add(line .. repeat(' ', maxWidth - strdisplaywidth(line)))
    endfor

    return image
enddef


# {a_colors}: PureWidget.colors
# {opts}:
#   rOff: row offset
#   cOff: column offset
export def MoveColors(a_colors: dict<list<list<any>>>,
        opts: dict<number>): dict<list<list<any>>>
    var rOff: number = opts->get('rOff', 0)
    var cOff: number = opts->get('cOff', 0)
    var colors: dict<list<list<any>>> = a_colors->deepcopy()

    if rOff != 0
        colors = {}
        for [k, v] in a_colors->items()
            colors[str2nr(k) + rOff] = v
        endfor
    endif

    if cOff != 0
        for [k, v] in colors->items()
            for i in v->len()->range()
                v[i][0] += cOff
                v[i][1] += cOff
            endfor
        endfor
    endif

    return colors
enddef


# Compose({widget} [, {opts}])
# {opts}:
#   width/height/align
# Return:
#   [image, colors]
export def Compose(widget: Widget, opts: dict<any> = {}): list<any>
    var width: number = opts->get('width', widget.width)
    var height: number = opts->get('height', widget.height)
    var align = opts->get('align', widget.align)
    var image: list<string> = widget.image->deepcopy()
    var colors: dict<list<list<any>>> = widget.colors->deepcopy()

    # horizontal
    if align == kLeft || align == kTopLeft || align == kBotLeft
        for i in image->len()->range()
            var padding = width - image[i]->strdisplaywidth()
            if padding <= 0
                continue
            endif
            image[i] = image[i] .. repeat(' ', padding)
        endfor
    elseif align == kRight || align == kTopRight || align == kBotRight
        for i in image->len()->range()
            var padding = width - image[i]->strdisplaywidth()
            if padding <= 0
                continue
            endif
            image[i] = repeat(' ', padding) .. image[i]
            if colors->has_key(i)
                var tmp = colors[i]
                for j in tmp->len()->range()
                    tmp[j][0] += padding
                    tmp[j][1] += padding
                endfor
            endif
        endfor
    elseif align == kCenter || align == kTop || align == kBottom
        for i in image->len()->range()
            var padding = width - image[i]->strdisplaywidth()
            if padding <= 0
                continue
            endif
            var lPad: number = padding / 2
            var rPad = padding - lPad
            image[i] = repeat(' ', lPad) .. image[i] .. repeat(' ', rPad)
            if colors->has_key(i)
                var tmp = colors[i]
                for j in tmp->len()->range()
                    tmp[j][0] += lPad
                    tmp[j][1] += lPad
                endfor
            endif
        endfor
    endif

    # handle vertical
    var padding = height - image->len()

    if padding <= 0
        return [image, colors]
    endif

    if align == kCenter || align == kLeft || align == kRight
        var bPad: number = padding / 2
        var uPad = padding - bPad
        image = [ repeat(' ', width) ]->repeat(uPad) + image +
            [ repeat(' ', width) ]->repeat(bPad)

        var tmp: dict<list<list<any>>> = {}
        for [k, v] in colors->items()
            tmp[str2nr(k) + uPad] = v
        endfor
        colors = tmp
    elseif align == kTopLeft || align == kTop || align == kTopRight
        image += [ repeat(' ', width) ]->repeat(padding)
    elseif align == kBottom || align == kBotLeft || align == kBotRight
        image = [ repeat(' ', width) ]->repeat(padding) + image

        var tmp: dict<list<list<any>>> = {}
        for [k, v] in colors->items()
            tmp[str2nr(k) + padding] = v
        endfor
        colors = tmp
    endif

    return [image, colors]
enddef


# Test suit {{{ #
# test Widget in unit.vim
if 0
    class W implements Widget
        var image: list<string> = []
        var dispWidth: number
        var dispHeight: number
        var height: number
        var width: number
        var parent: PureWidget = null_object
        var colors: dict<list<list<any>>>
        var align: Align

        def new(parent: PureWidget = null_object)
            this.parent = parent
        enddef

        def SetWidth(width: number): void
            this.width = width
        enddef

        def SetHeight(height: number): void
            this.height = height
        enddef

        def SetDirty(dirty: bool = true): void
        enddef

        def SetAlign(align: Align): void
            this.align = align
        enddef

        def SetParent(parent: PureWidget): void
            this.parent = parent
        enddef

        def SetImage(a_image: any): void
            this.image = a_image->type() == v:t_list ?
                a_image : a_image->split("\n")
        enddef

        def SetColor(a_colors: dict<list<list<any>>>): void
            this.colors = a_colors
        enddef

        def Render(): void
        enddef
    endclass

    def TestCompose(): void
        var w1 = W.new()
        w1.SetImage(['hello'])
        w1.SetColor({ 0: [[0, 1, 'a']] })
        w1.SetWidth(10)
        w1.SetHeight(3)

        var image: list<string>
        var hlInfo: dict<list<any>>
        # w1.SetAlign(kTop)
        # w1.SetAlign(kCenter)
        # w1.SetAlign(kBottom)
        # w1.SetAlign(kTopLeft)
        # w1.SetAlign(kLeft)
        # w1.SetAlign(kBotLeft)
        # w1.SetAlign(kTopRight)
        # w1.SetAlign(kRight)
        w1.SetAlign(kBotRight)
        [image, hlInfo] = w1->Compose()
        echo image
        echo hlInfo
    enddef

    TestCompose()
endif
# }}} Test suit #
