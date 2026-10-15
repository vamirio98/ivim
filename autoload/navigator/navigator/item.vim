vim9script


const k_navigatorCharIcon: dict<string> = {
    " ": '󱁐',
    "\<tab>": '',
    "\<cr>": '󰘌',
    "\<bs>": '',
    "\<up>": '󰁞',
    "\<down>": '󰁆',
    "\<left>": '󰁎',
    "\<right>": '󰁕',
}


def GetName(Value: any): string
    var t = type(Value)
    if t == v:t_list
        return Value[0]
    elseif t == v:t_dict
        return printf("%s%s", g:navigatorGroupIcon,
            get(Value, 'name', g:navigatorGroupName))
    elseif t == v:t_string
        return Value
    elseif t == v:t_func
        return GetName(Value())
    else
        return ''
    endif
enddef


def GetIcon(key: string): string
    return get(g:navigatorCharIcon, key, get(k_navigatorCharIcon, key, key))
enddef


# key order: alpha, number, other
export def Compile(a_data: dict<any>): list<string>
    var data: list<string> = []
    for [k, V] in items(a_data)
        var text = printf("%s %s %s",
            GetIcon(k),
            g:navigatorSep, GetName(V))
        data->add(text)
    endfor

    def Norm(x: number): number
        if (x >= char2nr('a') && x <= char2nr('z')) ||
                (x >= char2nr('A') && x <= char2nr('Z'))
            return x - 256
        elseif x >= char2nr('0') && x <= char2nr('9')
            return x - char2nr('9') - 1
        else
            return x
        endif
    enddef

    data->sort((x: string, y: string) => {
        var nx = char2nr(x[0])
        var ny = char2nr(y[0])
        nx = Norm(nx)
        ny = Norm(ny)
        return nx < ny ? -1 : (nx > ny ? 1 : 0)
    })
    return data
enddef
