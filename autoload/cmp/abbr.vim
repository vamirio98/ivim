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
    var lines = execute('ia', 'silent!')
    if lines =~? gettext('No abbreviation found')
        return v:none  # Suppresses warning message
    endif
    var items = []
    for line in lines->split("\n")
        var m = line->matchlist('\v^%(i|!)\s+\zs(\S+)\s+(.*)$')
        if m->len() > 2 && m[1]->stridx(base) == 0
            items->add({
                word: m[1],
                info: m[2],
                dup: 1,
                kind: mUtil.GetItemKindValue('Abbrev')
            })
        endif
    endfor
    return items->empty() ? v:none :
        items->sort((v1, v2) => v1.word < v2.word ? -1 : v1.word ==# v2.word ? 0 : 1)
enddef
