vim9script

import autoload 'util/str.vim' as mStr


# return image and index of the item following it
def GenImage(a_items: list<string>, a_args: list<number>
        ): tuple<list<string>, number>
    var [start, w, h] = a_args
    var colWidth: list<number> = []
    var itemNum = len(a_items)

    var totalWidth: number = 0
    var [r, c] = [0, 0]
    while start < itemNum && totalWidth < w
        r = 0
        var maxw: number = 0
        while r < h && start < itemNum
            maxw = max([maxw, mStr.DispLen(a_items[start])])
            start += 1
            r += 1
        endwhile
        colWidth->add(maxw)
        totalWidth += (c > 0 ? g:navigatorSpacing : 0) + maxw
        c += 1
    endwhile

    var image: list<string> = []
    var endup: number = start
    start = a_args[0]
    itemNum = endup - start
    var colNum = len(colWidth)
    for i in range(h)
        var line: string = ''
        for j in range(colNum)
            var index = i + j * h
            if index >= endup
                break
            endif
            line ..= (j > 0 ? repeat(' ', g:navigatorSpacing) : '') ..
                a_items[index] ..
                repeat(' ', colWidth[j] - mStr.DispLen(a_items[index]))
        endfor
        if empty(line)
            break
        endif
        image->add(line)
    endfor
    return (image, endup)
enddef


export def Open(a_items: list<string>, a_opts: dict<any> = {}): number
    var w: number = float2nr(g:navigatorPopupWidth * &columns)
    var h: number = float2nr(g:navigatorPopupHeight * &lines)
    var images: list<list<string>> = []

    var itemNum = len(a_items)
    var start = 0
    while start < itemNum
        var [image, endup] = GenImage(a_items, [start, w, h - 1])
        images->add(image)
        start = endup
    endwhile
    var wid = popup_create(images[0], {
        line: &lines,
        col: (&columns - w) / 2,
        pos: 'botleft',
        minwidth: w,
        minheight: h,
        maxwidth: w,
        maxheight: h,
        padding: g:navigatorPadding,
    })
    return wid
enddef


# test suit {{{ #
if 0
    import autoload './item.vim' as mItem
    var items = {
        'a': 'apple', 'b': 'banana', 'c': 'code', 'd': 'decide', 'e': 'eight',
        'f': 'first', 'g': 'google', 'h': 'hello', 'i': 'initialize',
        'j': 'join', 'k': 'key'
    }
    Open(mItem.Compile(items))
endif
# }}} test suit #
