vim9script

import autoload './string.vim' as str
import autoload './debug.vim'

var Assert = debug.Assert
var Equal = debug.Equal
var NotEqual = debug.NotEqual

def TestReplace(): bool
    return Equal(str.Replace('ababababa', 'b', 'c'), 'acacacaca') &&
        Equal(str.Replace('abababa', 'ab', 'c'), 'ccca')
enddef

def TestStrip(): bool
    var s: string = "\t\t\r\r\n\n  a  \n\n\r\r\t\t"
    return Equal(str.Strip(s), 'a') &&
        Equal(str.Lstrip(s), "a  \n\n\r\r\t\t") &&
        Equal(str.Rstrip(s), "\t\t\r\r\n\n  a")
enddef

def TestPartition(): bool
    return Equal(str.Partition('abcabc', 'ca'), ('ab', 'ca', 'bc'))
enddef

def TestSearch(): bool
    var s: string = 'abcabcabc'
    return Assert(s->str.Startswith('a')) &&
        Assert(!s->str.Startswith('b')) &&
        Assert(s->str.Endswith('c')) &&
        Assert(!s->str.Endswith('b')) &&
        Assert(s->str.Contains('b')) &&
        Assert(!s->str.Contains('e')) &&
        Equal(s->str.Between('a', 'c'), (0, 2)) &&
        Equal(s->str.Between('a', 'c', 8), (-1, -1)) &&
        Equal(s->str.Matchat('abc', 8), (6, 9, 'abc')) &&
        Equal(s->str.Matchat('acb', 8), (-1, -1, null_string))
enddef

def Test(): bool
    return TestReplace() && TestStrip() && TestPartition() &&
        TestSearch()
enddef

Test()
