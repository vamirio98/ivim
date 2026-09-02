vim9script

# should not depend on anything

# set <leader> key.
g:mapleader = '\'
g:maplocalleader = "\<tab>"

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
        exec $"set <M-{key}>=\e{key}"
        exec $"imap \e{key} <M-{key}>"
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
    tnoremap <M-q> <C-\><C-n>
endif

# resize window {{{
# increase window height
nnoremap <C-up> <Cmd>resize +2<CR>
# decrease window height
nnoremap <C-down> <Cmd>resize -2<CR>
# decrease window width
nnoremap <C-left> <Cmd>vertical resize -2<CR>
# increase window width
nnoremap <C-right> <Cmd>vertical resize +2<CR>
# }}}

# move lines {{{
# move down
nnoremap <M-J> <Cmd>exec 'move .+'.v:count1<CR>==
# move up
nnoremap <M-K> <Cmd>exec 'move .-'.(v:count1 + 1)<CR>==

inoremap <M-J> <Esc><Cmd>m .+1<CR>==gi
inoremap <M-K> <Esc><Cmd>m .-2<CR>==gi
vnoremap <M-J> :<C-u>exec "'<,'>move '>+".v:count1<CR>gv=gv
vnoremap <M-K> :<C-u>exec "'<,'>move '<-".(v:count1 + 1)<CR>gv=gv
# }}}

# buffers {{{ #
# prev buffer
nnoremap <S-h> <Cmd>bprevious<CR>
# next buffer
nnoremap <S-l> <Cmd>bnext<CR>

nnoremap [b <Cmd>bprevious<CR>
nnoremap ]b <Cmd>bnext<CR>
# }}} buffers #

# next search result {{{
# https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
nnoremap <expr> n 'Nn'[v:searchforward] .. 'zv'
xnoremap <expr> n 'Nn'[v:searchforward]
onoremap <expr> n 'Nn'[v:searchforward]
nnoremap <expr> N 'nN'[v:searchforward] .. 'zv'
xnoremap <expr> N 'nN'[v:searchforward]
onoremap <expr> N 'nN'[v:searchforward]
# }}}

# save file
nnoremap <C-s> <Cmd>update<CR>
inoremap <C-s> <Cmd>update<CR>

# keywordprg
nnoremap <space>K <Cmd>norm! K<CR>

# better indenting
vnoremap < <gv
vnoremap > >gv

# add undo break-points
inoremap , ,<C-g>u
inoremap . .<C-g>u
inoremap ; ;<C-g>u

# previous quickfix
nnoremap [q <Cmd>cprev<CR>
# next quickfix
nnoremap ]q <Cmd>cnext<CR>

nnoremap Q <Cmd>qa<CR>

# {{{ scroll popup window
# https://vi.stackexchange.com/a/21927
nnoremap <expr> <C-F> <SID>ScrollCursorPopup(true) ? '<esc>' : '<C-F>'
nnoremap <expr> <C-B> <SID>ScrollCursorPopup(false) ? '<esc>' : '<C-B>'
def FindCursorPopup(radius: number = 2): number
    var srow: number = screenrow()
    var scol: number = screencol()

    # it's necessary to test entire rect, as some popup might be quite small
    for r in range(srow - radius, srow + radius)
        for c in range(scol - radius, scol + radius)
            var winid: number = popup_locate(r, c)
            if winid != 0
                return winid
            endif
        endfor
    endfor

    return 0
enddef

def ScrollCursorPopup(down: bool): bool
    var winid: number = FindCursorPopup()
    if winid == 0
        return false
    endif

    var pp = popup_getpos(winid)
    popup_setoptions( winid, {'firstline': pp.firstline + ( down ? 4 : -4 ) } )
    return true
enddef
# }}}

# split window
nnoremap <space>- <C-w>s
nnoremap <space><bar> <C-w>v
# close window
nnoremap <space>wd <C-w>c
