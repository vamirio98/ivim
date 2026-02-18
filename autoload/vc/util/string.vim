vim9script

#----------------------------------------------------------------------
# string replace
#----------------------------------------------------------------------
export def Replace(text: string, old: string, new: string): string
    return substitute(text, old, new, 'g')
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
# string partition
#----------------------------------------------------------------------
export def Partition(text: string, sep: string): tuple<string, string, string>
var pos = stridx(text, sep)
    if pos < 0
        return (text, '', '')
    else
        var size = strlen(sep)
        var head = strpart(text, 0, pos)
        var newSep = strpart(text, pos, size)
        var tail = strpart(text, pos + size)
        return (head, newSep, tail)
    endif
enddef


#----------------------------------------------------------------------
# starts with prefix
#----------------------------------------------------------------------
export def Startswith(text: string, prefix: string): bool
    return (empty(prefix) || (stridx(text, prefix) == 0))
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
    return (empty(suffix) || (stridx(text, suffix, ss) == ss))
enddef


#----------------------------------------------------------------------
# check if text contains part
#----------------------------------------------------------------------
export def Contains(text: string, part: string): bool
    return stridx(text, part) >= 0
enddef


#----------------------------------------------------------------------
# get range
# Between({text}, {begin}, {endup} [, {pos}])
# {begin} The head token
# {endup} The tail token
# {pos} Start search from where
#----------------------------------------------------------------------
export def Between(text: string, begin: string, endup: string,
        pos: number = 0): tuple<number, number>
    var p1 = stridx(text, begin, pos)
    if p1 < 0
        return (-1, -1)
    endif
    var tmp = p1 + len(begin)
    var p2 = stridx(text, endup, tmp)
    if p2 < 0
        return (-1, -1)
    endif
    return (p1, p2)
enddef


#----------------------------------------------------------------------
# Matchat({text}, {pat} ,{pos})
# return matched text at certain position
#----------------------------------------------------------------------
export def Matchat(text: string, pat: string,
        pos: number): tuple<number, number, string>
    var start = match(text, pat, 0)
    while (start >= 0) && (start <= pos)
        var endup = matchend(text, pat, start)
        if (start <= pos) && (endup > pos)
            return (start, endup, strpart(text, start, endup - start))
        else
            start = match(text, pat, endup)
        endif
    endwhile
    return (-1, -1, null_string)
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

    def TestPartition(): bool
        return Equal(Partition('abcabc', 'ca'), ('ab', 'ca', 'bc'))
    enddef

    def TestSearch(): bool
        var s: string = 'abcabcabc'
        return Assert(s->Startswith('a')) &&
            Assert(!s->Startswith('b')) &&
            Assert(s->Endswith('c')) &&
            Assert(!s->Endswith('b')) &&
            Assert(s->Contains('b')) &&
            Assert(!s->Contains('e')) &&
            Equal(s->Between('a', 'c'), (0, 2)) &&
            Equal(s->Between('a', 'c', 8), (-1, -1)) &&
            Equal(s->Matchat('abc', 8), (6, 9, 'abc')) &&
            Equal(s->Matchat('acb', 8), (-1, -1, null_string))
    enddef

    def Test(): bool
        return TestReplace() && TestStrip() && TestPartition() &&
            TestSearch()
    enddef

    Test()
endif
# }}} Testing suit. #
