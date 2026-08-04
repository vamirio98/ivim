vim9script

g:whichKey = {}

export def CreateCache(forceUpdate: bool = false): void
    if exists('b:whichKeyCache') && !forceUpdate
        return
    endif
    b:whichKeyCache = g:whichKey->deepcopy()
    if exists('b:whichKey')
        b:whichKeyCache->extend(b:whichKey, 'force')
    endif
enddef

export def AddGroup(a_keySeq: string, a_name: string,
        a_buffer: bool = false, refresh: bool = false): void
enddef

export def AddDesc(a_keySeq: string, a_desc: any,
        a_buffer: bool = false, refresh: bool = false): void
    if a_keySeq->len() <= 1
        throw $'key sequence must longger than 1'
    endif

    var root = a_buffer ? get(b:, 'whichKey', {}) : g:whichKey
    for i in (a_keySeq->len() - 1)->range()
        const c: string = a_keySeq[i]
        if !root->has_key(c)
            root[c] = {}
        endif
        root = root[c]
    endfor
    root[a_keySeq[-1]] = a_desc
enddef
