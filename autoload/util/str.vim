vim9script

#----------------------------------------------------------------------
# string replace
#----------------------------------------------------------------------
export def Replace(text: string, pat: string, new: string): string
    return substitute(text, pat, new, 'g')
enddef


#----------------------------------------------------------------------
# string strip
#----------------------------------------------------------------------
export def Strip(text: string): string
    return substitute(text, '^[\t\r\n ]*\(.\{-}\)[\t\r\n ]*$', '\1', '')
enddef


#----------------------------------------------------------------------
# strip left
#----------------------------------------------------------------------
export def Lstrip(text: string): string
    return substitute(text, '^[\t\r\n ]*', '', '')
enddef


#----------------------------------------------------------------------
# strip left
#----------------------------------------------------------------------
export def Rstrip(text: string): string
    return substitute(text, '[\t\r\n ]*$', '', '')
enddef


#----------------------------------------------------------------------
# starts with prefix
#----------------------------------------------------------------------
export def Startswith(text: string, prefix: string): bool
    return empty(prefix) || stridx(text, prefix) == 0
enddef


#----------------------------------------------------------------------
# ends with suffix
#----------------------------------------------------------------------
export def Endswith(text: string, suffix: string): bool
    var s1 = len(text)
    var s2 = len(suffix)
    var ss = s1 - s2
    if s1 < s2
        return false
    endif
    return empty(suffix) || stridx(text, suffix, ss) == ss
enddef


#----------------------------------------------------------------------
# Matchat({text}, {pat} ,{pos})
# return matched text at certain position
#----------------------------------------------------------------------
export def Matchat(text: string, pat: string,
        pos: number): tuple<number, number, string>
    var start = match(text, pat, 0)
    while start >= 0 && start <= pos
        var endup = matchend(text, pat, start)
        if start <= pos && endup > pos
            return (start, endup, strpart(text, start, endup - start))
        else
            start = match(text, pat, endup)
        endif
    endwhile
    return (-1, -1, null_string)
enddef


export def List(a_text: any): list<string>
    if type(a_text) == v:t_list
        var res: list<string> = []
        for i in a_text->len()->range()
            res->add(a_text[i]->type() == v:t_string ?
                a_text[i] : string(a_text[i]))
        endfor
        return res
    else
        var text: string = type(a_text) == v:t_string ? a_text : string(a_text)
        return text->split("\n", 1)
    endif
enddef


export def DispLen(text: string): number
    return strdisplaywidth(text)
enddef


# Testing suit. {{{ #
if 0
    import autoload './debug.vim'

    var Assert = debug.Assert
    var Equal = debug.Equal
    var NotEqual = debug.NotEqual

    def TestReplace(): bool
        return Equal(Replace('ababababa', 'b', 'c'), 'acacacaca') &&
            Equal(Replace('abababa', 'ab', 'c'), 'ccca')
    enddef

    def TestStrip(): bool
        var s: string = "\t\t\r\r\n\n  a  \n\n\r\r\t\t"
        return Equal(Strip(s), 'a') &&
            Equal(Lstrip(s), "a  \n\n\r\r\t\t") &&
            Equal(Rstrip(s), "\t\t\r\r\n\n  a")
    enddef

    def TestSearch(): bool
        var s: string = 'abcabcabc'
        return Assert(s->Startswith('a')) &&
            Assert(!s->Startswith('b')) &&
            Assert(s->Endswith('c')) &&
            Assert(!s->Endswith('b'))
    enddef

    def Test(): bool
        return TestReplace() && TestStrip() && TestSearch()
    enddef

    Test()
endif
# }}} Testing suit. #
