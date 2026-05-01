vim9script

export enum Align
    Left,  # only for horizontal
    Right, # only for horizontal
    Center # for horizontal and vertical
endenum

const Left = Align.Left
const Right = Align.Right
const Center = Align.Center

export interface PureWidget
    var image: list<string>
    var height: number  # 1-based
    var width: number
    var hlInfos: dict<list<any>>  # [rowOff, [colOff1, colOff2, highlight] ]

    var parent: PureWidget

    def SetParent(parent: PureWidget): void
endinterface

export interface Widget extends PureWidget
    var align: Align

    def SetAlign(align: Align): void
    def Render(): void
endinterface


# {opts}:
#   width: aim width
#   height: aim height
# Return:
#   [image, hlInfos]
export def ComposeWidget(widget: Widget, a_opts: dict<any>): list<any>
    var defOpts: dict<any> = {
        width: 4,
        height: 1,
    }
    var opts = defOpts->extend(a_opts)
    var width: number = opts.width
    var height: number = opts.height
    var image: list<string> = widget.image->deepcopy()
    var hlInfos: dict<list<any>> = widget.hlInfos->deepcopy()
    var align = widget.align

    # handle horizontal
    if align == Left
        for i in image->len()->range()
            var padding = width - image[i]->strdisplaywidth()
            image[i] = image[i] .. repeat(' ', padding)
        endfor
    elseif align == Right
        for i in image->len()->range()
            var padding = width - image[i]->strdisplaywidth()
            image[i] = repeat(' ', padding) .. image[i]
            if hlInfos->has_key(i)
                for j in hlInfos->len()->range()
                    hlInfos[j][0] += padding
                    hlInfos[j][1] += padding
                endfor
            endif
        endfor
    else
        for i in image->len()->range()
            var padding = width - image[i]->strdisplaywidth()
            var lPad: number = padding / 2
            var rPad = padding - lPad
            image[i] = repeat(' ', lPad) .. image[i] .. repeat(' ', rPad)
            if hlInfos->has_key(i)
                for j in hlInfos->len()->range()
                    hlInfos[j][0] += lPad
                    hlInfos[j][1] += lPad
                endfor
            endif
        endfor
    endif

    # handle vertical
    var padding = height - image->len()
    var bPad: number = padding / 2
    var uPad = padding - bPad
    image = [ repeat(' ', width) ]->repeat(uPad) + image +
        [ repeat(' ', width) ]->repeat(bPad)

    var tmp: dict<list<any>> = {}
    for [k, v] in hlInfos->items()
        tmp[str2nr(k) + uPad] = v
    endfor

    return [image, tmp]
enddef


# Test suit {{{ #
if 0
    class W implements Widget
        var image: list<string> = []
        var height: number
        var width: number
        var parent: PureWidget = null_object
        var hlInfos: dict<list<any>>
        var align: Align

        def new(parent: PureWidget = null_object)
            this.parent = parent
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

        def SetHlInfo(a_hlInfos: dict<list<any>>): void
            this.hlInfos = a_hlInfos
        enddef

        def Render(): void
        enddef
    endclass

    def TestComposeWidget(): void
        var w1 = W.new()
        w1.SetImage(['hello'])
        w1.SetHlInfo({ 0: [0, 1, 'a'] })

        var image: list<string>
        var hlInfo: dict<list<any>>
        # [image, hlInfo] =
        #     w1->ComposeWidget({ width: 10, height: 3 })
        # w1.SetAlign(Left)
        # [image, hlInfo] =
        #     w1->ComposeWidget({ width: 10, height: 3})
        w1.SetAlign(Right)
        [image, hlInfo] =
            w1->ComposeWidget({ width: 10, height: 3})
        echo image
        echo hlInfo
    enddef

    TestComposeWidget()
endif
# }}} Test suit #
