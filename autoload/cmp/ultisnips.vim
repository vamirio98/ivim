vim9script

import autoload './util.vim' as mUtil


export def Completor(findstart: number, base: string): any
    if findstart == 1
        var prefix = getline('.')->strpart(0, col('.') - 1)->matchstr('\S\+$')
        if prefix->empty()
            return -2
        endif
        return col('.') - prefix->len() - 1
    endif

    var snips = []
    for [k, v] in UltiSnips#SnippetsInCurrentScope()->items()
        snips->add({
            word: k,
            info: v,
            kind: mUtil.GetItemKindValue('Snippet')
        })
    endfor
    return empty(snips) ? v:none : snips
enddef
