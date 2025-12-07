vim9script

# From https://github.com/girishji/vimcomplete/

import autoload './util.vim'

export var options: dict<any> = {
    dup: true,
}

export def Setup(): void
    # Turn off LSP client even if this module is disabled. Otherwise LSP will
    # open a separate popup window with completions.
    if exists('*g:LspOptionsSet')
        var lspOpts = {
            useBufferCompletion: false,
            snippetSupport: true,
            vsnipSupport: false,
            ultisnipsSupport: false,
            autoComplete: false,
            omniComplete: true,
        }
        if options->has_key('completionMatcher')
            lspOpts->extend({completionMatcher: options.completionMatcher})
        endif
        g:LspOptionsSet(lspOpts)
    endif
enddef

export def Completor(findstart: number, base: string): any
    if !exists('*g:LspOmniFunc') || !exists('*g:LspServerRunning') ||
            !g:LspServerRunning(&ft)
        return -2  # cancel but stay in completion mode
    endif

    if findstart == 1
        var index = g:LspOmniFunc(findstart, base)
        return index
    endif

    var items = g:LspOmniFunc(findstart, base)
    if !options.dup
        items->map((_, v) => v->extend({ dup: 0 }))
    endif
    items = items->mapnew((_, v) => {
        var ud = v.user_data
        if type(ud) == v:t_dict
            if !v->has_key('kind_hlgroup')
                v.kind_hlgroup = util.GetKindHighlightGroup(ud->get('kind', ''))
            endif
            v.kind = ud->has_key('kind') ? util.GetItemKindValue(ud.kind) : ''
        endif
        return v
    })
    return { words: items, refresh: "always" }
enddef
