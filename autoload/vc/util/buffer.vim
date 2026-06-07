vim9script

import autoload './path.vim'
import autoload './os.vim'
import autoload './string.vim' as str
import autoload './notify.vim'


class NamedBufMgr
    var _dict: dict<number> = {}
    var _list: list<number> = []

    def new()
    enddef

    def Exists(buf: any): bool
        if type(buf) == v:t_number
            return this._list->index(buf) >= 0
        elseif type(buf) == v:t_string
            return this._dict->has_key(buf)
        else
            return false
        endif
    enddef

    def GetBufnr(name: string): number
        return this._dict[name]
    enddef

    def Add(buf: number, name: string): number
        if this._list->index(buf) >= 0 || this._dict->has_key(name)
            throw $'[{buf}]({name}) is already exists'
        endif
        this._dict[name] = buf
        this._list->add(buf)
        return buf
    enddef

    def Del(buf: any): number
        var t = buf->type()
        if t == v:t_string && this._dict->has_key(buf)
            var bnr: number = this._dict[buf]
            this._dict->remove(buf)
            return this._list->remove(this._list->index(bnr))
        elseif t == v:t_number && this._list->index(buf) >= 0
            var key: string
            for [k, v] in this._dict->items()
                if v == buf
                    key = k
                    break
                endif
            endfor
            this._dict->remove(key)
            return this._list->remove(this._list->index(buf))
        else
            return -1
        endif
    enddef

    def Clear(): list<number>
        var res: list<number> = this._list
        this._dict = {}
        this._list = []
        return res
    enddef
endclass


# for anonymous buffers
var s_anon: list<number> = []
# for named buffers
var s_named: NamedBufMgr = NamedBufMgr.new()
# for objects
var s_objs: dict<any> = {}

const kNameKey: string = '__name__'
const kPathKey: string = '__path__'


export def GetBufnr(buf: any): number
    if type(buf) == v:t_number
        return buf
    else
        var bufnr = s_named.GetBufnr(buf)
        return bufnr >= 0 ? bufnr : bufnr(buf)
    endif
enddef


export def GetObj(buf: any): dict<any>
    var bnr: number = GetBufnr(buf)
    if !s_objs->has_key(buf)
        s_objs[bnr] = {}
    endif
    return s_objs[bnr]
enddef


export def GetName(buf: any): string
    var obj = GetObj(buf)
    return get(obj, kNameKey, null_string)
enddef


export def GetPath(buf: any): string
    var obj = GetObj(buf)
    return get(obj, kPathKey, null_string)
enddef


#---------------------------------------------------------------
# setbufvar
#---------------------------------------------------------------
export def SetVar(buf: any, varname: string, value: any): void
    var obj = GetObj(buf)
    obj[varname] = value
enddef


#---------------------------------------------------------------
# getbufvar
#---------------------------------------------------------------
export def GetVar(buf: any, varname: string, default: any = null): any
    var obj = GetObj(buf)
    return get(obj, varname, default)
enddef


#---------------------------------------------------------------
# autocmd
#---------------------------------------------------------------
export def Autocmd(buf: any, event: string, funcname: string): void
    var bnr: number = GetBufnr(buf)
    exec $'au {event} <buffer={bnr}> {funcname}'
enddef


#---------------------------------------------------------------
# remove all autocmd
#---------------------------------------------------------------
export def NoAutocmd(buf: any, event: string): void
    var bnr: number = GetBufnr(buf)
    exec $'au! {event} <buffer={bnr}>'
enddef


#---------------------------------------------------------------
# sync buffer to disk
#---------------------------------------------------------------
export def Sync(buf: any): void
    var bnr: number = GetBufnr(buf)
    var curBnr: number = bufnr('%')
    silent exec 'buffer' bnr
    silent exec 'update'
    silent exec 'buffer' curBnr
enddef


#---------------------------------------------------------------
# update buffer content
#---------------------------------------------------------------
export def Update(buf: any, lines: any): number
    var bnr: number = GetBufnr(buf)
    var text: list<string> = str.List(lines)
    var modifiable: bool = getbufvar(bnr, '&modifiable', 0)
    var res: number = (!deletebufline(bnr, 1, '$') &&
        !setbufline(bnr, 1, text)) ? 0 : 1
    setbufvar(bnr, '&modifiable', modifiable)
    return res
enddef


#---------------------------------------------------------------
# clear buffer content
#---------------------------------------------------------------
export def Clear(buf: any): number
    return Update(buf, [])
enddef


#---------------------------------------------------------------
# append text to buffer
#---------------------------------------------------------------
export def AddLine(buf: any, lnum: any, lines: any): number
    var bnr: number = GetBufnr(buf)
    var text: list<string> = str.List(lines)
    var modifiable: bool = getbufvar(bnr, '&modifiable', 0)
    setbufvar(bnr, '&modifiable', 1)
    var res: number = appendbufline(bnr, lnum, text)
    setbufvar(bnr, '&modifiable', modifiable)
    return res
enddef


#---------------------------------------------------------------
# delete line [first, last]
#---------------------------------------------------------------
export def DelLine(buf: any, first: any, last: any = null): number
    var bnr: number = GetBufnr(buf)
    var modifiable: bool = getbufvar(bnr, '&modifiable', 0)
    setbufvar(bnr, '&modifiable', 1)
    var res: number = deletebufline(bnr, first, last)
    setbufvar(bnr, '&modifiable', modifiable)
    return res
enddef


#---------------------------------------------------------------
# setbufline
#---------------------------------------------------------------
export def SetLine(buf: any, lnum: any, lines: any): number
    var bnr: number = GetBufnr(buf)
    var text: list<string> = str.List(lines)
    var modifiable: bool = getbufvar(bnr, '&modifiable', 0)
    setbufvar(bnr, '&modifiable', 1)
    var res: number = setbufline(bnr, lnum, text)
    setbufvar(bnr, '&modifiable', modifiable)
    return res
enddef


#---------------------------------------------------------------
# getbufline [first, last]
#---------------------------------------------------------------
export def GetLine(buf: any, first: any, last: any = null): list<string>
    var bnr: number = GetBufnr(buf)
    return getbufline(bnr, first, last)
enddef


#---------------------------------------------------------------
# alloc a new buffer
#
# Alloc([{named} [, {name}]])
# {hasName}: whether to allow a named buffer
# {name}: buffer name, if it's empty, a random name will be used
#
# return: buffer number the new buffer
#---------------------------------------------------------------
export def Alloc(hasName: bool = false, name: string = null_string): number
    var bnr: number = -1
    var fpath: string = null_string
    var fname: string = name

    if !hasName
        if !s_anon->empty()
            bnr = s_anon->remove(-1)
        else
            silent bnr = bufadd('')
        endif
    else
        if fname != null
            fpath = path.Join(os.TmpDir(), fname)
        else
            fpath = os.TmpFile()
            fname = path.Basename(fpath)
        endif
        if s_named.Exists(fname)
            throw $'{name} is already exists'
        endif
        silent bnr = bufadd(fpath)
        s_named.Add(bnr, fname)
    endif

    silent bufload(bnr)
    # make buffer a scratch buffer, see :h scratch
    setbufvar(bnr, '&buflisted', 0)
    setbufvar(bnr, '&bufhidden', 'hide')
    setbufvar(bnr, '&buftype', 'nofile')
    setbufvar(bnr, 'noswapfile', 1)

    if hasName
        SetVar(bnr, kNameKey, fname)
        SetVar(bnr, kPathKey, fpath)
    endif
    setbufvar(bnr, '&filetype', '')

    return bnr
enddef


#---------------------------------------------------------------
# free a buffer
#---------------------------------------------------------------
export def Free(buf: any): void
    var bnr: number = GetBufnr(buf)
    NoAutocmd(bnr, '*')
    var fpath: string = null_string
    if s_named.Exists(bnr)  # a named buffer
        fpath = GetVar(bnr, kPathKey)
        s_named.Del(bnr)
        silent exec $'bwipeout! {bnr}'
        delete(fpath)
    else  # a anonymous buffer
        Clear(bnr)
        s_anon->add(bnr)
    endif
    s_objs->remove(bnr)
enddef


# clear all buffers when leave vim
def ClearOnExit(): void
    var err: bool = false
    var buffers: list<number> = s_named.Clear()
    for bnr in buffers
        var fpath: string = GetVar(bnr, kPathKey, '')
        if fpath->empty() || delete(fpath) != 0
            err = true
            continue
        endif
    endfor
    if err
        notify.Error('some tmp file may be leave after vim exit')
    endif
enddef

augroup VcAutoloadUtilBuffer
    au!
    # # FIXME: it's strange that any named buffer can not be found on disk
    # even if after call Sync()
    # au VimLeavePre * ClearOnExit()
augroup END
