vim9script


export def Start(a_visual: bool, a_args: string, a_line1: number,
        a_line2: number, a_count: number): void
    var visual: string = a_visual ? 'normal! gv' : ''
    var root: dict<any> = null_dict
    if a_args !~ '\v^\*:[A-Za-z0-9#_]+$'
        root = eval(a_args)
    else
        root = {}
        var name = a_args[2 :]
        for scope in [ 'g:', 'b:', 't:' ]
            var vname = scope .. name
            if !exists(vname)
                root->extend(eval(vname), 'force')
            endif
        endfor
    endif

    # get callable

    # exec callable
enddef
