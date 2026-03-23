vim9script

const kAttrList = [
    'bold',
    'underline',
    'reverse',
    'inverse',  # same as reverse
    'italic',
    'standout',  # standout mode is reverse on many terminals, bold on others
    'nocombine',
    'NONE',
]

const kTypeList = [
    'term',
    'cterm',
    'gui',
]

# Param: {all}: also clear 'linksto'
export def Clear(color: string, clearLink: bool = true): void
    var info = { 'name': color, 'cleared': true }
    if clearLink
        info.linksto = 'NONE'
    endif
    if hlset([info]) < 0
        throw $'Failed to clear "{color}"'
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
#   {color}: highlight name
#   {feature}: all feature need to enable, dict or list
#       if is a dict, all features will be set to specific status
#       if is a list, all featrues will be enable
#   {types}: 'term', 'cterm', 'gui'
#
# Return: {color}
export def EnableFeature(color: string, feature: any,
        types: any = kTypeList): string
    var tmp = hlget(color, true)
    if tmp->empty()
        throw $'No color "{color}"'
    endif
    var info = tmp[0]

    DoEnableFeature(info, feature, types)

    return color
enddef


export def Extend(newColor: string, color: string, feature: any = {},
        types: any = kTypeList): string
    var tmp = hlget(color, true)
    if tmp->empty()
        throw $'No color "{color}"'
    endif
    var info = tmp[0]

    info.name = newColor
    DoEnableFeature(info, feature, types)

    return newColor
enddef


export def Combine(newColor: string, fgColor: string, bgColor: string): string
    var tmp = hlget(fgColor, true)
    var fgInfo = get(tmp, 0, {})
    tmp = hlget(bgColor, true)
    var bgInfo = get(tmp, 0, {})
    for key in ['ctermfg', 'guifg']
        if fgInfo->has_key(key)
            bgInfo[key] = fgInfo[key]
        endif
    endfor

    bgInfo.name = newColor
    bgInfo.force = true
    if hlset([bgInfo]) < 0
        throw $'Failed to combine "{fgColor}" and "{bgColor}"'
    endif

    return newColor
enddef


if 0
    def Test(): void
        hi CurSearch
        'VcTestHighlight'->Extend('CurSearch', 'underline')
        hi VcTestHighlight
        'VcTestHighlight'->EnableFeature('bold')
        hi VcTestHighlight
        Clear('VcTestHighlight')
        hi VcTestHighlight
        hi Comment
        hi CursorLine
        Combine('VcTestHighlight', 'Comment', 'CursorLine')
            ->EnableFeature({'reverse': false, 'bold': true})
        hi VcTestHighlight
    enddef

    Test()
endif
