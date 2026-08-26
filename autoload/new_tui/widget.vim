vim9script

import autoload 'util/str.vim' as mStr

# use to calculate what to show, so do not have popup
export interface BgWidget
    var id: number
    var parent: BgWidget
    var image: list<string>
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
    var image: list<string>
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

    var _prop: list<any> = []  # relative to self, prop = (x, y) + _prop
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
        this._prop = deepcopy(prop)
        this._ditry = 1
    enddef

    # call twice when render, first, calculate the size of itself;
    # sencond, calculate the text proprities
    def Render(first: bool): void
        if !this._dirty
            return
        endif

        if first
            this.h = len(this.image)
            var w = 0
            for line in this.image
                w = max([w, mstr.DispLen(line)])
            endfor
            this.w = w

            return
        endif

        this.prop = MoveProp(this._prop, this.row, this.col)

        this._dirty = 0
    enddef
endclass
