vim9script

# should not depend on anything

# {{{ make sure function work normally
# set Alt and function key in terminal

# disable ALT on GUI, make it can be used for mapping
set winaltkeys=no

set timeoutlen=500

# turn on function key timeout detection (the function key in the
# terminal is a charset starts with ESC)
set ttimeout

# function key timeout detection: 50ms
set ttimeoutlen=50

if $TMUX != ''
    set ttimeoutlen=30
elseif &ttimeoutlen > 80 || &ttimeoutlen <= 0
    set ttimeoutlen=80
endif
# use ALT in terminal, should set ttimeout and ttimeoutlen at first
# refer: http://www.skywind.me/blog/archives/2021
if !has('gui_running')
    def SetMetacode(key: string)
        exec $'set <M-{key}>=\e{key}'
        exec $'imap \e{key} <M-{key}>'
    enddef
    for i in range(10)
        SetMetacode(nr2char(char2nr('0') + i))
    endfor
    for i in range(26)
        SetMetacode(nr2char(char2nr('a') + i))
        SetMetacode(nr2char(char2nr('A') + i))
    endfor
    for c in [',', '.', '/', ';', '{', '}']
        SetMetacode(c)
    endfor
    for c in ['?', ':', '-', '_', '+', '=', "'"]
        SetMetacode(c)
    endfor
endif

# use function key in terminal
def SetFunctionKey(name: string, code: string)
    exec $'set {name}=\e{code}'
enddef
if has('gui_running') == 0
    SetFunctionKey('<F1>', 'OP')
    SetFunctionKey('<F2>', 'OQ')
    SetFunctionKey('<F3>', 'OR')
    SetFunctionKey('<F4>', 'OS')
    SetFunctionKey('<S-F1>', '[1;2P')
    SetFunctionKey('<S-F2>', '[1;2Q')
    SetFunctionKey('<S-F3>', '[1;2R')
    SetFunctionKey('<S-F4>', '[1;2S')
    SetFunctionKey('<S-F5>', '[15;2~')
    SetFunctionKey('<S-F6>', '[17;2~')
    SetFunctionKey('<S-F7>', '[18;2~')
    SetFunctionKey('<S-F8>', '[19;2~')
    SetFunctionKey('<S-F9>', '[20;2~')
    SetFunctionKey('<S-F10>', '[21;2~')
    SetFunctionKey('<S-F11>', '[23;2~')
    SetFunctionKey('<S-F12>', '[24;2~')
endif
# }}}

# cursor moving {{{
# move in insert mode.
inoremap <C-a> <home>
inoremap <C-e> <end>
inoremap <M-h> <left>
inoremap <M-j> <down>
inoremap <M-k> <up>
inoremap <M-l> <right>

# move in command mode.
cnoremap <M-h> <left>
cnoremap <M-j> <down>
cnoremap <M-k> <up>
cnoremap <M-l> <right>
cnoremap <C-a> <home>
cnoremap <C-e> <end>

# move between windows.
nnoremap <M-h> <C-w>h
nnoremap <M-j> <C-w>j
nnoremap <M-k> <C-w>k
nnoremap <M-l> <C-w>l
# }}}

# terminal
if has('terminal') && exists(':terminal') == 2 && has('patch-8.1.1')
    set termwinkey=<C-_>
    tnoremap <esc><esc> <C-\><C-n>
endif
