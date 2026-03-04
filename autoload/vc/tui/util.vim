vim9script

import autoload '../util/string.vim' as str

# Object. {{{ #
# Get tab/global object.
export def Object(tab: bool = false): dict<any>
    if tab
        if !exists('t:_vcTuiObj')
            t:_vcTuiObj = {}
        endif
        return t:_vcTuiObj
    else
        if !exists('g:_vcTuiObj')
            g:_vcTuiObj = {}
        endif
        return g:_vcTuiObj
    endif
enddef

# Get buffer object.
export def BufObj(buf: any): dict<any>
    const kName = '_vcTuiObj'
    var bid: number = type(buf) == v:t_number ? buf : bufnr(buf)
    if !bufexists(bid)
        return null_dict
    endif
    var obj = getbufvar(bid, kName)
    if type(obj) != v:t_dict
        setbufvar(bid, kName, {})
        obj = getbufvar(bid, kName)
    endif
    return obj
enddef


# Get window object.
export def WinObj(winid: number): dict<any>
    const kName = '_vcTuiObj'
enddef
# }}} Object. #


# String. {{{ #
# Remove all tailing '\t\r\n ' in string list.
export def StrListNormalize(textlist: any): list<string>
    var tl: list<string>
    if type(textlist) == v:t_list
        tl = textlist
    else
        tl = (type(textlist) == v:t_string ? textlist : string(textlist))->split("\n", 1)
    endif

    var res: list<string> = []
    for text in tl
        var tmp = text->str.Rstrip()
        res->add(tmp)
    endfor

    return res
enddef
# }}} String. #
