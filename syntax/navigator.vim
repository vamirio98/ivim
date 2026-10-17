vim9script


def ColorWithSeparator()
    var sep = g:navigatorSep
    exec 'syntax match NavigatorSeparator /' .. sep .. '/ contained'
    exec 'syntax match NavigatorKey' '/\(^\s*\|\s\{2,}\)\S.\{-}' .. sep .. '/' 'contains=NavigatorSeparator'
    syntax match NavigatorGroup / +[0-9A-Za-z_/-]*/
    syntax region NavigatorItem start='^[^(Navigator)]' end='$' contains=NavigatorKey, NavigatorGroup, NavigatorSeparator
    syntax region NavigatorFoot start='^Navigator' end='$'
enddef


#---------------------------------------------------------------
# main
#---------------------------------------------------------------
syntax clear

if !empty(g:navigatorSep)
    ColorWithSeparator()
endif

b:current_syntax = 'navigator'

#---------------------------------------------------------------
# highlight
#---------------------------------------------------------------
highlight default link NavigatorKey Error
highlight default link NavigatorSeparator Type
highlight default link NavigatorGroup Function
highlight default link NavigatorItem Number

highlight default link NavigatorHead Tabline
highlight default link NavigatorFoot Tabline
