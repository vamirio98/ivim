vim9script

import autoload 'util/str.vim' as mStr


def DoGenImage(items: list<string>, width: number, height: number,
        a_start: number): tuple<list<string>, number>
    var wPerCol: list<number> = []
    var itemNum = len(items)
    var start = a_start
    var [tpad, rpad, bpad, lpad] = g:navigatorPadding
    var hPerRow = height - tpad - bpad

    var wTotal = lpad + rpad
    var [r, c] = [0, 0]
    while start < itemNum && wTotal < width
        r = 0
        var maxw = 0
        while r < hPerRow && start < itemNum
            maxw = max([maxw, mStr.DispLen(items[start])])
            start += 1
            r += 1
        endwhile
        wPerCol->add(maxw)
        wTotal += (c > 0 ? g:navigatorSpacing : 0) + maxw
        c += 1
    endwhile

    var image: list<string> = [' '->repeat(width)]->repeat(tpad)
    var endup = start
    start = a_start
    itemNum = endup - start
    for i in range(hPerRow)
        var line = ' '->repeat(lpad)
        for j in range(len(wPerCol))
            var index = i + j * hPerRow
            if index >= endup
                break
            endif
            line ..= (j > 0 ? ' '->repeat(g:navigatorSpacing) : '') ..
                items[index] ..
                ' '->repeat(wPerCol[j] - mStr.DispLen(items[index]))
        endfor
        if len(line) == lpad
            break
        endif
        image->add(line .. ' '->repeat(rpad))
    endfor
    return (image, endup)
enddef


# return image and index of the item following it
def GenImage(items: list<string>, a_path: string): list<string>
    var w = float2nr(g:navigatorPopupWidth * &columns)
    var h = float2nr(g:navigatorPopupHeight * &lines)
    var subImg: list<list<string>> = []
    var itemNum = len(items)
    var start = 0
    while start < itemNum
        # height min 1 for footnote
        var [img, endup] = DoGenImage(items, w, h - 1, start)
        subImg->add(img)
        start = endup
    endwhile

    var image: list<string> = []
    var imgNum = len(subImg)
    for i in range(imgNum)
        var lfootnote = printf("Navigator (page %d/%d): %s", i, imgNum, a_path)
        var rfootnote = "(C-j/k: paging, BS: return, ESC: quit)"
        subImg[i]->add(printf("%s%s%s", lfootnote,
            ' '->repeat(w - mStr.DispLen(lfootnote) - mStr.DispLen(rfootnote)),
            rfootnote))
        image += subImg[i]
    endfor

    return image
enddef


def Filter(winid: number, key: string): bool
    if key == "\<esc>" || key == "\<C-c>"
        popup_close(winid)
        return 1
    endif
    return 0
enddef


export def Open(a_items: list<string>, a_opts: dict<any> = {}): number
    var image = GenImage(a_items, 'k')
    var w = float2nr(g:navigatorPopupWidth * &columns)
    var h = float2nr(g:navigatorPopupHeight * &lines)

    var winid = popup_create(image, {
        line: &lines - 2,
        col: (&columns - w) / 2,
        pos: 'botleft',
        minwidth: w,
        minheight: h,
        maxwidth: w,
        maxheight: h,
        filter: Filter,
    })
    win_execute(winid, 'set ft=navigator')
    return winid
enddef


# test suit {{{ #
if 0
    import autoload './item.vim' as mItem
    var items = {
        'a': 'apple', 'b': 'banana', 'c': 'code', 'd': 'decide', 'e': 'eight',
        'f': 'first', 'g': 'google', 'h': 'hello', 'i': 'initialize',
        'j': 'join', 'k': 'key', 'l': { 'a': 'a' }, 'm': { 'name': 'group' },
    }
    Open(mItem.Compile(items))
endif
# }}} test suit #
