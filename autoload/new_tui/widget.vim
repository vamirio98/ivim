vim9script

import autoload 'util/str.vim' as mStr

# use to calculate what to show, so do not have popup
export interface BgWidget
    var id: number
    var parent: BgWidget
    var image: list<string>  # each line should have the same length
    var row: number
    var col: number
    var w: number
    var h: number
    var prop: list<any>  # text properities, format: [[lnum, col, props]],
                         # each item is the arguments of prop_add()

    def SetId(id: number): void
    def SetParent(parent: BgWidget): void
    def SetRow(row: number): void
    def SetCol(col: number): void

    # call twice when render, first, calculate the size of itself;
    # sencond, calculate the text proprities
    def Render(first: bool): void
endinterface


# use to show a image, bind with popup window, usually used as the top widget
export interface Widget extends BgWidget
    # anything that BgWidget has
    var id: number
    var parent: BgWidget
    var image: list<string>  # each line should have the same length
    var row: number
    var col: number
    var w: number
    var h: number
    var prop: list<any>  # text properities, format: [[lnum, col, props]],
                         # each item is the arguments of prop_add()

    def SetId(id: number): void
    def SetParent(parent: BgWidget): void
    def SetRow(row: number): void
    def SetCol(col: number): void

    # call twice when render, first, calculate the size of itself;
    # sencond, calculate the text proprities
    def Render(first: bool): void

    # Widget own
    var win: number
    var buf: number
    var minW: number
    var minH: number
    var maxW: number
    var maxH: number

    def SetMinW(w: number): void
    def SetMinH(h: number): void
    def SetMaxW(w: number): void
    def SetMaxH(h: number): void
endinterface


export def MoveProp(a_prop: list<any>, drow: number, dcol: number): list<any>
    var prop = deepcopy(a_prop)

    for p in prop
        # format [lnum, col, props]
        p[0] += drow
        p[1] += dcol
        if p[2]->has_key('end_lnum')
            p[2]['end_lnum'] += drow
        endif
        if p[2]->has_key('end_col')
            p[2]['end_col'] += dcol
        endif
    endfor

    return prop
enddef


export class StaticWidget implements BgWidget
    var id: number = -1
    var parent: BgWidget = null_object
    var image: list<string> = []
    var row: number = 0
    var col: number = 0
    var w: number = 0
    var h: number = 0
    var prop: list<any> = []

    var _rprop: list<any> = []  # relative to self, prop = (x, y) + _rprop
    var _dirty: bool = 1

    def SetId(id: number): void
        this.id = id
    enddef

    def SetParent(parent: BgWidget): void
        this.parent = parent
    enddef

    def SetRow(row: number): void
        if row <= 0
            throw 'invalid param'
        endif
        this.row = row
        this._dirty = 1
    enddef

    def SetCol(col: number): void
        if col <= 0
            throw 'invalid param'
        endif
        this.col = col
        this._dirty = 1
    enddef

    def SetImage(image: list<string>): void
        this.image = deepcopy(image)
        this._dirty = 1
    enddef

    def SetProp(prop: list<any>): void
        this._rprop = deepcopy(prop)
        this._dirty = 1
    enddef

    # call twice when render, first, calculate the size of itself;
    # sencond, calculate the text proprities
    def Render(first: bool): void
        if !this._dirty
            return
        endif

        if first
            this.h = len(this.image)
            this.w = this.h > 0 ? mStr.DispLen(this.image[0]) : 0

            return
        endif

        this.prop = MoveProp(this._rprop, this.row, this.col)

        this._dirty = 0
    enddef
endclass


export class BasicWidget implements Widget
    # anything that BgWidget has
    var id: number = -1
    var parent: BgWidget = null_object
    var image: list<string> = []
    var row: number = 0
    var col: number = 0
    var w: number = 0
    var h: number = 0
    var prop: list<any> = []

    def SetId(id: number): void
        this.id = id
    enddef

    def SetParent(parent: BgWidget): void
        this.parent = parent
    enddef

    def SetRow(row: number): void
        this.row = row
    enddef

    def SetCol(col: number): void
        this.col = col
    enddef

    # call twice when render, first, calculate the size of itself;
    # sencond, calculate the text proprities
    def Render(first: bool): void
    enddef

    # Widget own
    var win: number = -1
    var buf: number = -1
    var minW: number = 0
    var minH: number = 0
    var maxW: number = 0
    var maxH: number = 0

    def SetMinW(w: number): void
        this.minW = w
    enddef

    def SetMinH(h: number): void
        this.minH = h
    enddef

    def SetMaxW(w: number): void
        this.maxW = w
    enddef

    def SetMaxH(h: number): void
        this.maxH = h
    enddef
endclass


def PadImage(a_image: list<string>, nlpad: number, nrpad: number,
        ntpad: number, nbpad: number): list<string>
    var image: list<string> = []
    var lpad: string = ' '->repeat(nlpad)
    var rpad: string = ' '->repeat(nrpad)
    var lineLen: number = nlpad + nrpad +
        (empty(a_image) ? 0 : mStr.DispLen(a_image[0]))
    var line: string = ' '->repeat(lineLen)

    for l in a_image
        image->add(lpad .. l .. rpad)
    endfor
    image = [line]->repeat(ntpad) + image + [line]->repeat(nbpad)

    return image
enddef


# make image a square
export def FillImage(a_image: list<string>): list<string>
    var maxw: number = 0
    for line in a_image
        maxw = max(maxw, mStr.DispLen(line))
    endfor

    var image: list<string> = []
    for line in a_image
        image->add(line .. ' '->repeat(maxw - mStr.DispLen(line)))
    endfor

    return image
enddef


# {align}: 'center', 'top', 'bottom', 'left', 'right'
# return: (image, drow, dcol)
export def BuildImage(a_image: list<string>, a_w: number, a_h: number,
        align: string): tuple<list<string>, number, number>
    var drow: number = 0
    var dcol: number = 0
    var oh = len(a_image)
    var ow = oh > 0 ? mStr.DispLen(a_image[0]) : 0
    if oh > a_h || ow > a_w
        throw '`image` is too large'
    endif

    var nlpad: number = 0
    var nrpad: number = 0
    var ntpad: number = 0
    var nbpad: number = 0
    if align == 'center'
        if ow < a_w
            nlpad = (a_w - ow) / 2
            nrpad = (a_w - ow - nlpad)
            dcol = nlpad
        endif
        if oh < a_h
            ntpad = (a_h - oh) / 2
            nbpad = (a_h - oh - ntpad)
            drow = ntpad
        endif
    elseif align == 'top'
        if ow < a_w
            nlpad = (a_w - ow) / 2
            nrpad = (a_w - ow - nlpad)
            dcol = nlpad
        endif
        nbpad = a_h - oh
    elseif align == 'bottom'
        if ow < a_w
            nlpad = (a_w - ow) / 2
            nrpad = (a_w - ow - nlpad)
            dcol = nlpad
        endif
        ntpad = a_h - oh
        drow = ntpad
    elseif align == 'left'
        if oh < a_h
            ntpad = (a_h - oh) / 2
            nbpad = (a_h - oh - ntpad)
            drow = ntpad
        endif
    elseif align == 'right'
        if oh < a_h
            ntpad = (a_h - oh) / 2
            nbpad = (a_h - oh - ntpad)
            drow = ntpad
        endif
        nlpad = a_w - ow
        dcol = nlpad
    else
        throw $'unsupported align: {align}'
    endif

    var image = PadImage(a_image, nlpad, nrpad, ntpad, nbpad)

    return (image, drow, dcol)
enddef
