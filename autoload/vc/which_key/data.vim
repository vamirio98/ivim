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

def TrKeySeq(a_keySeq: string): string
    return a_keySeq->substitute('\c<leader>', g:mapleader, 'g')
        ->substitute('\c<localleader>', g:maplocalleader, 'g')
enddef

def BuildDict(a_keySeq: string, a_buffer: bool): dict<any>
    var root = a_buffer ? get(b:, 'whichKey', {}) : g:whichKey
    for i in a_keySeq->len()->range()
        const c: string = a_keySeq[i]
        if !root->has_key(c)
            root[c] = {}
        endif
        root = root[c]
    endfor
    return root
enddef

export def AddGroup(a_keySeq: string, a_name: string,
        a_buffer: bool = false, refresh: bool = false): void
    var keySeq: string = TrKeySeq(a_keySeq)
    if keySeq->empty()
        throw $'key sequence is empty'
    endif
    var root = BuildDict(keySeq, a_buffer)
    root['name'] = a_name
enddef

export def AddDesc(a_keySeq: string, a_desc: any,
        a_buffer: bool = false, refresh: bool = false): void
    var keySeq: string = TrKeySeq(a_keySeq)
    if keySeq->len() <= 1
        throw $'key sequence must longger than 1'
    endif

    var root = BuildDict(keySeq[: -2], a_buffer)
    root[keySeq[-1]] = a_desc
enddef
