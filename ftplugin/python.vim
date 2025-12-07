vim9script

setlocal shiftwidth=4
setlocal tabstop=4
setlocal softtabstop=4
setlocal expandtab

if line('$') == 1 && getline(1) == ''
    setline(1, '#!/usr/bin/env python3')
    setline(2, '# -*- coding: utf-8 -*-')
    setline(3, '')

    exec 'normal G'
    exec 'startinsert!'
endif
