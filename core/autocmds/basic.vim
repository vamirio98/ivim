vim9script

# no dependence

packadd nohlsearch

packadd hlyank
g:hlput_enable = true


if has('gui_running')
    if has('win32') || has('win64')
        augroup VcCoreAutocmdsBasicGuiWin32
            au!
            au GUIEnter * simalt ~x
        augroup END
    endif
endif
