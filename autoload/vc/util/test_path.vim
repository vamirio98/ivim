vim9script

import autoload './path.vim'
import autoload './debug.vim'

var Assert = debug.Assert


def TestIsPath(): bool
    return Assert(path.IsPath('.')) && Assert(path.IsPath('..')) &&
        Assert(path.IsPath('./')) && Assert(path.IsPath('../')) &&
        Assert(path.IsPath('./a')) && Assert(path.IsPath('../a')) &&
        Assert(path.IsPath('./a/..')) && Assert(path.IsPath('../a/..')) &&
        Assert(!path.IsPath('...')) &&
        Assert(path.IsPath('C:/')) && Assert(path.IsPath('C:\\')) &&
        Assert(path.IsPath('C:/a')) && Assert(path.IsPath('C:\\a')) &&
        Assert(path.IsPath('C:/a\\..')) && Assert(path.IsPath('C:\\a/..')) &&
        Assert(path.IsPath('/tmp')) && Assert(path.IsPath('/tmp/')) &&
        Assert(path.IsPath('/tmp/..')) && Assert(path.IsPath('/tmp\\..')) &&
        Assert(!path.IsPath('https://')) && Assert(!path.IsPath(''))
enddef

def Test(): void
    TestIsPath()
enddef

Test()
