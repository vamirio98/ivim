vim9script


export def ObjMgr(): dict<any>
    if !exists('t:_vcTuiObj')
        t:_vcTuiObj = {}
    endif
    return t:_vcTuiObj
enddef


# Get window object
export def ObjAcquire(winid: number): dict<any>
    var mgr = ObjMgr()
    if !mgr->has_key(winid)
        mgr[winid] = {}
    endif
    return mgr[winid]
enddef


# Free window object
export def ObjRelease(winid: number): void
    var mgr = ObjMgr()
    if mgr->has_key(winid)
        mgr->remove(winid)
    endif
enddef
