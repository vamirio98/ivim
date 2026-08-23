vim9script

# provide the buffer that NOT written to disk, used for backgroud

import autoload './str.vim' as mStr

const kBufObjName: string = 'vc'

def InitBuffer(bnr: number): number
    bufload(bnr)

    # make buffer a scratch buffer, see :h scratch
    setbufvar(bnr, '&buflisted', 0)
    setbufvar(bnr, '&bufhidden', 'hide')
    setbufvar(bnr, '&buftype', 'nofile')
    setbufvar(bnr, 'noswapfile', 1)

    # do not allow write to disk
    setbufvar(bnr, '&write', 0)

    # clear buffer
    setbufvar(bnr, '&filetype', '')
    setbufvar(bnr, '&modifiable', 1)
    deletebufline(bnr, 1, '$')
    setbufvar(bnr, kBufObjName, {})

    return bnr
enddef


export def GetObj(bnr: number): dict<any>
    if !bufexists(bnr)
        return null_dict
    endif
    var obj = getbufvar(bnr, kBufObjName, null)
    if obj == null || type(obj) != v:t_dict
        setbufvar(bnr, kBufObjName, {})
        obj = getbufvar(bnr, kBufObjName)
    endif
    return obj
enddef


export def SetVar(bnr: number, a_name: string, a_value: any): void
    var obj = GetObj(bnr)
    obj[a_name] = a_value
enddef


export def GetVar(bnr: number, a_name: string, a_default: any = null): any
    var obj = GetObj(bnr)
    return get(obj, a_name, a_default)
enddef


export def Update(bnr: number, a_lines: any): number
    var lines: list<string> = mStr.List(a_lines)

    var mod: bool = getbufvar(bnr, '&modifiable', 1)
    setbufvar(bnr, '&modifiable', 1)
    defer () => {
        setbufvar(bnr, '&modifiable', mod)
    }()

    return deletebufline(bnr, 1, '$') || setbufline(bnr, 1, lines)
enddef


export def Clear(bnr: number): number
    return Update(bnr, [])
enddef


export def AppendLine(bnr: number, lnum: any, a_lines: any): number
    var lines: list<string> = mStr.List(a_lines)

    var mod: bool = getbufvar(bnr, '&modifiable', 1)
    setbufvar(bnr, '&modifiable', 1)
    defer () => {
        setbufvar(bnr, '&modifiable', mod)
    }()

    return appendbufline(bnr, lnum, lines)
enddef


export def DeleteLine(bnr: number, first: any, last: any = v:none): number
    var mod: bool = getbufvar(bnr, '&modifiable', 1)
    setbufvar(bnr, '&modifiable', 1)
    defer () => {
        setbufvar(bnr, '&modifiable', mod)
    }()

    return deletebufline(bnr, first, last)
enddef


export def SetLine(bnr: number, lnum: any, a_lines: any): number
    var mod: bool = getbufvar(bnr, '&modifiable', 1)
    setbufvar(bnr, '&modifiable', 1)
    defer () => {
        setbufvar(bnr, '&modifiable', mod)
    }()

    var lines: list<string> = mStr.List(a_lines)
    return setbufline(bnr, lnum, lines)
enddef


export def GetLine(bnr: number, first: any, last: any = v:none): list<string>
    return getbufline(bnr, first, last)
enddef


var s_buffer: list<number> = []

export def Alloc(): number
    var bnr: number = -1
    if empty(s_buffer)
        silent bnr = bufadd('')
    else
        bnr = s_buffer->remove(-1)
    endif

    return InitBuffer(bnr)
enddef

# {func} will be called as `func(bnr)` when recycle buffer
export def SetDefer(bnr: number, A_func: func): void
    SetVar(bnr, 'defer', A_func)
enddef

export def Free(bnr: number): number
    var F: func = GetVar(bnr, 'defer', null_function)
    if F != null
        F(bnr)
    endif
    InitBuffer(bnr)
    s_buffer->add(bnr)
enddef
