vim9script

if line('$') == 1 && getline(1) == ''
    setline(1, '#!/bin/bash')
    setline(2, '')

    exec 'normal G'
    exec 'startinsert!'
endif
