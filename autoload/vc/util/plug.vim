vim9script

export def Has(plugin: string): bool
    # vim-plug store all plugin in the variable `g:plugs`
    return has_key(g:plugs, plugin)
enddef

export def PluginDir(plugin: string): string
    if !Has(plugin)
        throw 'no such plugin: ' .. plugin
    endif
    return g:plugs[plugin].dir
enddef
