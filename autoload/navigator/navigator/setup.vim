vim9script


def Root(visual: bool, buffer: bool): dict<any>
    if !visual
        if !buffer
            return g:navigator
        endif
        if !exists('b:navigator')
            b:navigator = {}
        endif
        return b:navigator
    else
        if !buffer
            return g:navigatorVisual
        endif
        if !exists('b:navigatorVisual')
            b:navigatorVisual = {}
        endif
        return b:navigatorVisual
    endif
enddef


# get root[...keys], create the miss item
def Locate(a_root: dict<any>, keys: string): dict<any>
    var root: dict<any> = a_root
    for key in keys
        if !root->has_key(key)
            root[key] = {}
        endif
        root = root[key]
    endfor
    return root
enddef


export def Group(a_visual: bool, a_keys: string, A_name: any,
        a_buffer: bool = false): void
    var root = Root(a_visual, a_buffer)
    root = Locate(root, a_keys)
    root['name'] = A_name
enddef


export def Desc(a_visual: bool, a_keys: string, A_value: any,
        a_buffer: bool = false): void
    var root = Root(a_visual, a_buffer)
    root = Locate(root, a_keys[: -2])
    root[a_keys[-1]] = A_value
enddef
