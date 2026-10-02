vim9script

import autoload 'util/msg.vim' as mMsg

var s_exportLines: list<string> = []

# NOTE: Only use for exported names from autoload.
# See:
#   https://vi.stackexchange.com/a/46973
#   https://stackoverflow.com/a/23650554
def g:VcUnletExported(): void
    var filename: string = expand('%:p:r')
    var tokens: list<string> = filename->split('[\\\/]\+')
    var index: number = -1
    for i in tokens->len()->range()
        if tokens[i] == 'autoload'
            index = i
            break
        endif
    endfor
    if index == -1
        # mMsg.Error('Only use for autoload file.')
        return
    endif
    filename = tokens[index + 1 : ]->join('#')

    s_exportLines = []
    try
        var saveView = winsaveview()
        keeppatterns g/^export/add(s_exportLines, getline('.'))
        winrestview(saveView)
    catch /^Vim\%((\a\+)\)\=:E486:/
        # mMsg.Warn('No export lines.')
        return
    endtry
    # echo s_exportLines

    var exportedVars: list<string> = []
    for line in s_exportLines
        var words: list<string> = line->substitute(':', '', 'g')->split('\ \+')

        if words[1] != 'abstract'
            if words[1] != 'def'
                exportedVars->add($'g:{filename}#{words[2]}')
            endif
        else
            # Handle abstract class exports.
            exportedVars->add($'g:{filename}#{words[3]}')
        endif
    endfor
    # echo exportedVars

    if exportedVars->empty()
        # All exports are for functions.
        # mMsg.Warn('No exported variables.')
        return
    endif
    for v in exportedVars
        if exists(v)
            # echom $'v: {v}'
            exec $':unlet {v}'
        endif
    endfor
enddef

def SourceVimrc(): void
    g:VcUnletExported()
    exec 'source %'
enddef

nnoremap <space>vs <scriptcmd>SourceVimrc()<cr>
