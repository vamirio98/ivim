vim9script

import autoload 'vc/util/notify.vim'

var sExportLines: list<string> = []

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
        notify.Error('Only use for autoload file.')
        return
    endif
    filename = tokens[index + 1 : ]->join('#')

    sExportLines = []
    try
        var saveView = winsaveview()
        keeppatterns g/^export/add(sExportLines, getline('.'))
        winrestview(saveView)
    catch /^Vim\%((\a\+)\)\=:E486:/
        notify.Warn('No export lines.')
        return
    endtry
    # echo sExportLines

    var exportedVars: list<string> = []
    for line in sExportLines
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
        notify.Warn('No exported variables.')
        return
    endif
    for v in exportedVars
        if exists(v)
            # echom $'v: {v}'
            exec $':unlet {v}'
        endif
    endfor
enddef

nnoremap <space>vu <cmd>call g:VcUnletExported()<cr>
