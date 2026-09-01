vim9script

const kTypeList = [
    'term',
    'cterm',
    'gui',
]


export def Clear(a_highlight: string, clearLink: bool = true): void
    var info = { 'name': a_highlight, 'cleared': true }
    if clearLink
        info.linksto = 'NONE'
    endif
    if hlset([info]) < 0
        throw $'Failed to clear "{a_highlight}"'
    endif
enddef


# Ensure attributes is a dict, not a string or list
def NormAttr(attr: any): dict<any>
    var t = attr->type()
    if t == v:t_dict
        return attr
    elseif t == v:t_string
        var opts = {}
        for key in attr->split(',')
            opts[key] = true
        endfor
        return opts
    else
        var opts = {}
        for key in attr
            opts[key] = true
        endfor
        return opts
    endif
enddef


# Ensure types is a list, not a string
def NormType(types: any): list<string>
    var t = types->type()
    if t == v:t_list
        return types
    else
        return types->split(',')
    endif
enddef


def DoEnableFeature(info: dict<any>, feature: any, types: any): void
    info.force = true
    var feat = feature->NormAttr()
    var aimTypes = types->NormType()
    for t in aimTypes
        # To remove an attribute, remove it from dict
        if info->has_key(t)
            info[t]->extend(feat, 'force')->filter((_, x) => x)
        else
            info[t] = feat->filter('v:val')
        endif
    endfor
    if hlset([info]) < 0
        throw $'Failed to enable feature [{feature}] for "{info.name}"'
    endif
enddef


# EnableFeature({name}, {feature})
# Param:
#   {highlight}: highlight name
#   {feature}: all feature need to enable, dict or list
#       if is a dict, all features will be set to specific status
#       if is a list, all featrues will be enable
#   {types}: 'term', 'cterm', 'gui'
#
# Return: {highlight}
export def EnableFeature(a_highlight: string, feature: any,
        types: any = kTypeList): string
    var tmp = hlget(a_highlight, true)
    if tmp->empty()
        throw $'No highlight "{a_highlight}"'
    endif
    var info = tmp[0]

    DoEnableFeature(info, feature, types)

    return a_highlight
enddef


export def Extend(newHighlight: string, highlight: string, feature: any = {},
        types: any = kTypeList): string
    var tmp = hlget(highlight, true)
    if tmp->empty()
        throw $'No highlight "{highlight}"'
    endif
    var info = tmp[0]

    info.name = newHighlight
    DoEnableFeature(info, feature, types)

    return newHighlight
enddef


export def Combine(newHighlight: string, fgHighlight: string,
        bgHighlight: string): string
    var tmp = hlget(fgHighlight, true)
    var fgInfo = get(tmp, 0, {})
    tmp = hlget(bgHighlight, true)
    var bgInfo = get(tmp, 0, {})
    for key in ['ctermfg', 'guifg']
        if fgInfo->has_key(key)
            bgInfo[key] = fgInfo[key]
        endif
    endfor

    bgInfo.name = newHighlight
    bgInfo.force = true
    if hlset([bgInfo]) < 0
        throw $'Failed to combine "{fgHighlight}" and "{bgHighlight}"'
    endif

    return newHighlight
enddef


export def SynClearCmd(): string
    return 'syn clear'
enddef

# NOTE: use character-offset, set {virtcol} to false if need byte-offset
# NOTE: region format: [col1, col2)
export def SynRegionCmd(highlight: string, row1: number, col1: number,
        row2: number, col2: number, virtcol: bool = true): string
    var colMode = virtcol ? 'v' : 'c'
    var cmd = $'syn region {highlight} '
    cmd ..= $'start=/\%{row1}l\%{col1}{colMode}/ '
    cmd ..= $'end=/\%{row2}l\%{col2}{colMode}/'
    return cmd
enddef


var s_guiCursor: list<dict<any>>

export def CursorHide(): void
    set t_ve=
    s_guiCursor = hlget("Cursor")
    hlset([{ name: 'Cursor', cleared: 1 }])
enddef

export def CursorShow(): void
    set t_ve&
    if hlget("Cursor")[0]->get('cleared', 0)
        hlset(s_guiCursor)
    endif
enddef
