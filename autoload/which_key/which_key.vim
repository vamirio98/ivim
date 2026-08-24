vim9script

import autoload 'vc/util/interact.vim' as mInteract
import autoload './char.vim' as mChar
import autoload './data.vim' as mData
import autoload './tui.vim' as mTui


# Invoke({key} [, {mode}])
# usage:
export def Invoke(a_key: string, mode: string = 'n'): void
    var seq: list<string> = [ a_key ]
    # if !getchar(1)
    #     return
    # endif

    mData.CreateCache(1)
    var root: dict<any> = b:whichKeyCache
    if !root->has_key(a_key)
        return
    endif
    root = root[a_key]
    mTui.OpenHint(root)

    while 1
        var c: string = null_string

        try
            c = getchar()->nr2char()
        catch /^Vim:Interrupt$/
            return
        endtry

        if c->mChar.IsCancel()
            return
        endif

        seq->add(c)
        if root->has_key(c)
            if root[c]->type() == v:t_dict
                root = root[c]
            else
                seq->join('')->feedkeys('m')
                break
            endif
        else
            # no desc found
            seq->join('')->feedkeys('m')
            break
        endif
    endwhile
enddef

if 1
    nnoremap <localleader>l <cmd>echo 'name'<cr>
    mData.AddDesc('<localleader>l', 'echo name')
    nnoremap <localleader> <scriptcmd>Invoke(g:maplocalleader)<cr>
endif
