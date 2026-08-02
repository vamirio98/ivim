vim9script

import autoload 'vc/util/interact.vim' as mInteract
import autoload './char.vim' as mChar

# Invoke({key} [, {mode}])
# usage:
def Invoke(a_key: string, mode: string = 'n'): void
    var seq: string = a_key
    # if !getchar(1)
    #     return
    # endif

    while 1
        var c: string = mInteract.Getchar()
        if c->mChar.IsTerm()
            break
        endif
        seq ..= c
    endwhile

    echo seq
enddef
