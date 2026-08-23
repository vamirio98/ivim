vim9script

import autoload 'util/os.vim' as mOs

if has('clipboard')
    set clipboard^=unnamed,unnamedplus
endif

if has('clipmethod')
    packadd osc52
    set clipmethod+=osc52
elseif (!empty($SSH_TTY) || mOs.IsWsl())
    # let vim clipboard sync with system
    # from https://www.zhihu.com/tardis/zm/ans/2156080913?source_id=1003
    def RawEcho(str: string)
        if filewritable('/dev/fd/2')
            writefile([str], '/dev/fd/2', 'b')
        else
            exec "silent! !echo" shellescape(str)
            redraw!
        endif
    enddef

    def Copy(): void
        var s: string = v:event.regcontents->str2blob()->base64_encode()
        s = "\e]52;c;" .. s .. "\x07"
        RawEcho(s)
    enddef

    augroup VcCoreOptsCopy
        au!
        au TextYankPost * Copy()
    augroup END
endif
