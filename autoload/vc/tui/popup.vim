vim9script

import autoload '../util/buffer.vim'
import autoload './util.vim'

g:vcTuiPopupBoraderchars = get(g:, 'vcTuiPopupBoraderchars', '─│─│╭╮╯╰')

const defaultOptions = {
    borderchars: util.ExtactBorderchars(g:vcTuiPopupBoraderchars),
}


var cache: list<number> = []

export def Alloc(): number
    if !cache->empty()
        return cache->remove(-1)
    endif

    var bnr: number = popup_create('', defaultOptions)
    return bnr
enddef


export def Free(bnr: number): void
    buffer.Clear(bnr)
    cache->add(bnr)
enddef
