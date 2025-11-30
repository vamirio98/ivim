vim9script

import autoload "../autoload/lib/ui.vim" as ui
import autoload "../autoload/module/option.vim" as option
import autoload "../autoload/module/keymap.vim" as keymap
import autoload "../autoload/module/utils.vim" as utils

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
if has('gui_running') == 0
  def SetMetacode(key: string)
    exec "set <M-" .. key .. ">=\e" .. key
    exec "imap \e" .. key .. " <M-" .. key .. ">"
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
  exec "set " .. name .. "=\e" .. code
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

type Option = option.Option
var SetGroup: func = keymap.SetGroup
var SetDesc: func = keymap.SetDesc

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

# buffers {{{
# prev buffer
nnoremap <S-h> <Cmd>bprevious<CR>
# next buffer
nnoremap <S-l> <Cmd>bnext<CR>
nnoremap [b <Cmd>bprevious<CR>
nnoremap ]b <Cmd>bnext<CR>

SetGroup('<leader>b', 'buffer')
# switch to other buffer
nnoremap <leader>bb <Cmd>e #<CR>
SetDesc('<leader>bb', 'Switch to Other Buffer')

# delete buffer
nnoremap <leader>bd <ScriptCmd>utils.BufDel()<CR>
SetDesc('<leader>bd', 'Delete Buffer')
# delete other buffers
nnoremap <leader>bo <ScriptCmd>utils.BufDelOther()<CR>
SetDesc('<leader>bo', 'Delete Other Buffers')
# delete buffer and window
nnoremap <leader>bD <cmd>:bd<cr>
SetDesc('<leader>bD', 'Delete Buffer & Window')
# }}}

# clear search on escape
nnoremap <Esc> <Esc><Cmd>nohlsearch<CR>
SetGroup('<leader>u', 'ui')
# clear search, diff update and redraw, taken from runtime/lua/_editor.lua
nnoremap <leader>ur <Cmd>noh<bar>diffupdate<bar>normal! <C-l><CR>
SetDesc('<leader>ur', 'Clear Hlsearch / Diff Update / Redraw')

# next search result {{{
# https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
nnoremap <expr> n 'Nn'[v:searchforward] .. 'zv'
xnoremap <expr> n 'Nn'[v:searchforward]
onoremap <expr> n 'Nn'[v:searchforward]
nnoremap <expr> N 'nN'[v:searchforward] .. 'zv'
xnoremap <expr> N 'nN'[v:searchforward]
onoremap <expr> N 'nN'[v:searchforward]
# }}}

# add undo break-points
inoremap , ,<C-g>u
inoremap . .<C-g>u
inoremap ; ;<C-g>u

# save file
nnoremap <C-s> <Cmd>update<CR>
inoremap <C-s> <Cmd>update<CR>

# keywordprg
nnoremap <silent> <leader>K <Cmd>norm! K<CR>

# better indenting
vnoremap < <gv
vnoremap > >gv

# new file
SetGroup('<leader>f', 'file')
nnoremap <leader>fn <Cmd>enew<CR>
SetDesc('<leader>fn', 'New File')

# {{{ location list/ quickfix list
SetGroup('<leader>x', 'location')
# location list
def ToggleLocList(): void
  var ll = getloclist(bufnr('%'))
  if len(ll) == 0
    ui.Warn('location list is empty')
    lclose
  else
    lopen
  endif
enddef
nnoremap <leader>xl <ScriptCmd>ToggleLocList()<CR>
SetDesc('<leader>xl', 'Toggle Location List')

SetGroup('<leader>x', 'quickfix')
# quickfix list
def ToggleQfList(): void
  var qf = getqflist({'bufnr': bufnr('%')})
  if len(qf) == 0
    ui.Warn('quickfix list is empty')
    cclose
  else
    copen
  endif
enddef
nnoremap <leader>xq <ScriptCmd>ToggleQfList()<CR>
SetDesc('<leader>xq', 'Toggle QuickFix List')

# previous quickfix
nnoremap [q <Cmd>cprev<CR>
# next quickfix
nnoremap ]q <Cmd>cnext<CR>
# }}}

# {{{ option
SetGroup('<leader>u', 'option')
var spell = Option.new('spell')
nnoremap <leader>us <ScriptCmd>spell.Toggle()<CR>
SetDesc('<leader>us', 'Toggle Spell')

var wrap = Option.new('wrap')
nnoremap <leader>uw <ScriptCmd>wrap.Toggle()<CR>
SetDesc('<leader>uw', 'Toggle Wrap')

var relativenumber = Option.new('relativenumber')
nnoremap <leader>uL <ScriptCmd>relativenumber.Toggle()<CR>
SetDesc('<leader>uL', 'Toggle Relative Line No')

def SetLineNo(enable: bool): void
  b:ivim_rnu = get(b:, 'ivim_rnu', &relativenumber)
  if !enable
    b:ivim_rnu = &relativenumber
    setlocal norelativenumber
  else
    exec 'setlocal' (b:ivim_rnu ? '' : 'no') .. 'relativenumber'
  endif
  setlocal number!
enddef
var number = Option.new('number', v:none, SetLineNo)
nnoremap <leader>ul <ScriptCmd>number.Toggle()<CR>
SetDesc('<leader>ul', 'Toggle Line No')

var conceallevel = Option.newOnOff('conceallevel', (&cole > 0 ? &cole : 2), 0)
nnoremap <leader>uc <ScriptCmd>conceallevel.Toggle()<CR>
SetDesc('<leader>uc', 'Toggle Conceal Lv')

var colorcolumn = Option.newOnOff('colorcolumn', (&cc == "" ? "81" : &cc), "")
nnoremap <leader>uC <ScriptCmd>colorcolumn.Toggle()<CR>
SetDesc('<leader>uC', 'Toggle Color Column')

# {{{ toggle paste mode
# set filetype to empty to avoid vim format paste content
def TogglePasteMode(): void
  var paste: bool = &paste
  if !paste
    b:ivim_original_filetype = &ft
    set paste
    set ft=
  else
    exe 'set ft=' .. b:ivim_original_filetype
    set nopaste
    unlet b:ivim_original_filetype
  endif
enddef
nnoremap <leader>up <ScriptCmd>TogglePasteMode()<CR>
SetDesc('<leader>up', 'Toggle Paste Mode')
# }}}

# }}}

nnoremap Q <Cmd>qa<CR>

# windows {{{
nnoremap <leader>- <C-w>s
SetDesc('<leader>-', 'Split Window Below')
nnoremap <leader><bar> <C-w>v
SetDesc('<leader>|', 'Split Window Right')
nnoremap <leader>wd <C-w>c
SetGroup('<leader>w', 'window')
SetDesc('<leader>wd', 'Close Window')

# toggle window maximize {{{
# https://github.com/szw/vim-maximizer/blob/master/plugin/maximizer.vim
def MaximizeWin(): void
  t:ivim_restore_win = {'before': winrestcmd()}
  vert resize | resize
  t:ivim_restore_win.after = winrestcmd()
  normal! ze
enddef
def RestoreWin(): void
  if exists('t:ivim_restore_win')
    silent! exec t:ivim_restore_win.before
    if t:ivim_restore_win.before != winrestcmd()
      exec "wincmd ="
    endif
    unlet t:ivim_restore_win
    normal! ze
  endif
enddef
def ToggleWinMax()
  if exists('t:ivim_restore_win') && t:ivim_restore_win.after == winrestcmd()
    RestoreWin()
  elseif winnr('$') > 1
    MaximizeWin()
  endif
enddef
nnoremap <leader>um <ScriptCmd>ToggleWinMax()<CR>
SetDesc('<leader>um', 'Toggle Win Maximize')
augroup ivim_restore_maximize_win_on_winleave
  au!
  au WinLeave * RestoreWin()
augroup END
# }}}

# }}}

# tabs {{{
# vim-which-key only recognize <Tab>, no <tab>
SetGroup('<leader><Tab>', 'tab')
nnoremap <leader><Tab>f <Cmd>tabfirst<CR>
SetDesc('<leader><Tab>f', 'First Tab')
nnoremap <leader><Tab>l <Cmd>tablast<CR>
SetDesc('<leader><Tab>l', 'Last Tab')
nnoremap <leader><Tab>o <Cmd>tabonly<CR>
SetDesc('<leader><Tab>o', 'Close Other Tabs')
nnoremap <leader><Tab>n <Cmd>tabnew<CR>
SetDesc('<leader><Tab>n', 'New Tab')
nnoremap <leader><Tab>d <Cmd>tabclose<CR>
SetDesc('<leader><Tab>d', 'Close Tab')
nnoremap [<Tab> <Cmd>tabprevious<CR>
SetDesc('[<Tab>', 'Prev Tab')
nnoremap ]<Tab> <Cmd>tabnext<CR>
SetDesc(']<Tab>', 'Next Tab')
# }}}

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
