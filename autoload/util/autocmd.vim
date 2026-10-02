vim9script

export def DoautocmdUserCmd(event: string): string
    if !exists($'#User#{event}')
        return ''
    endif
    return $'doautocmd <nomodeline> User {fnameescape(event)}'
enddef
