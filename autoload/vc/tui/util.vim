vim9script

import autoload '../util/string.vim' as str


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
