vim9script

import autoload 'vc/util/notify.vim'
import autoload 'vc/util/option.vim'
import autoload 'vc/util/keymap.vim'
import autoload 'vc/misc/buffer.vim'

type Option = option.Option
var SetGroup: func = keymap.SetGroup
var SetDesc: func = keymap.SetDesc

# buffers {{{
SetGroup('<space>b', 'buffer')
# switch to other buffer
nnoremap <space>bb <Cmd>e #<CR>
SetDesc('<space>bb', 'Switch to Other Buffer')

# delete buffer
nnoremap <space>bd <ScriptCmd>buffer.BufDel()<CR>
SetDesc('<space>bd', 'Delete Buffer')
# delete other buffers
nnoremap <space>bo <ScriptCmd>buffer.BufDelOther()<CR>
SetDesc('<space>bo', 'Delete Other Buffers')
# delete buffer and window
nnoremap <space>bD <cmd>:bd<cr>
SetDesc('<space>bD', 'Delete Buffer & Window')
# }}}

# clear search on escape
SetGroup('<space>u', 'ui')
# clear search, diff update and redraw, taken from runtime/lua/_editor.lua
nnoremap <space>ur <Cmd>noh<bar>diffupdate<bar>normal! <C-l><CR>
SetDesc('<space>ur', 'Clear Hlsearch / Diff Update / Redraw')

# new file
SetGroup('<space>f', 'file')
nnoremap <space>fn <Cmd>enew<CR>
SetDesc('<space>fn', 'New File')

# {{{ location list/ quickfix list
SetGroup('<space>x', 'location')
# location list
def ToggleLocList(): void
    var ll = getloclist(bufnr('%'))
    if len(ll) == 0
        notify.Warn('location list is empty')
        lclose
    else
        lopen
    endif
enddef
nnoremap <space>xl <ScriptCmd>ToggleLocList()<CR>
SetDesc('<space>xl', 'Toggle Location List')

SetGroup('<space>x', 'quickfix')
# quickfix list
def ToggleQfList(): void
    var qf = getqflist({'bufnr': bufnr('%')})
    if len(qf) == 0
        notify.Warn('quickfix list is empty')
        cclose
    else
        copen
    endif
enddef
nnoremap <space>xq <ScriptCmd>ToggleQfList()<CR>
SetDesc('<space>xq', 'Toggle QuickFix List')
# }}}

# {{{ option
SetGroup('<space>u', 'option')
var spell = Option.new('spell')
nnoremap <space>us <ScriptCmd>spell.Toggle()<CR>
SetDesc('<space>us', 'Toggle Spell')

var wrap = Option.new('wrap')
nnoremap <space>uw <ScriptCmd>wrap.Toggle()<CR>
SetDesc('<space>uw', 'Toggle Wrap')

var relativenumber = Option.new('relativenumber')
nnoremap <space>uL <ScriptCmd>relativenumber.Toggle()<CR>
SetDesc('<space>uL', 'Toggle Relative Line No')

def SetLineNo(enable: bool): void
    b:vc_rnu = get(b:, 'vc_rnu', &relativenumber)
    if !enable
        b:vc_rnu = &relativenumber
        setlocal norelativenumber
    else
        exec 'setlocal' (b:vc_rnu ? '' : 'no') .. 'relativenumber'
    endif
    setlocal number!
enddef
var number = Option.new('number', v:none, SetLineNo)
nnoremap <space>ul <ScriptCmd>number.Toggle()<CR>
SetDesc('<space>ul', 'Toggle Line No')

var conceallevel = Option.newOnOff('conceallevel', (&cole > 0 ? &cole : 2), 0)
nnoremap <space>uc <ScriptCmd>conceallevel.Toggle()<CR>
SetDesc('<space>uc', 'Toggle Conceal Lv')

var colorcolumn = Option.newOnOff('colorcolumn', (&cc == "" ? "81" : &cc), "")
nnoremap <space>uC <ScriptCmd>colorcolumn.Toggle()<CR>
SetDesc('<space>uC', 'Toggle Color Column')

# {{{ toggle paste mode
# set filetype to empty to avoid vim format paste content
def TogglePasteMode(): void
    var paste: bool = &paste
    if !paste
        b:vc_original_filetype = &ft
        set paste
        set ft=
    else
        exec 'set ft=' .. b:vc_original_filetype
        set nopaste
        unlet b:vc_original_filetype
    endif
enddef
nnoremap <space>up <ScriptCmd>TogglePasteMode()<CR>
SetDesc('<space>up', 'Toggle Paste Mode')
# }}}

# }}}

def SourceVimrc(): void
    g:VcUnletExported()
    exec 'source %'
enddef
nnoremap <space>vs <ScriptCmd>SourceVimrc()<cr>

# windows {{{
nnoremap <space>- <C-w>s
SetDesc('<space>-', 'Split Window Below')
nnoremap <space><bar> <C-w>v
SetDesc('<space>|', 'Split Window Right')
nnoremap <space>wd <C-w>c
SetGroup('<space>w', 'window')
SetDesc('<space>wd', 'Close Window')

# toggle window maximize {{{
# https://github.com/szw/vim-maximizer/blob/master/plugin/maximizer.vim
def MaximizeWin(): void
    t:vc_restore_win = {'before': winrestcmd()}
    vert resize | resize
    t:vc_restore_win.after = winrestcmd()
    normal! ze
enddef
def RestoreWin(): void
    if exists('t:vc_restore_win')
        silent! exec t:vc_restore_win.before
        if t:vc_restore_win.before != winrestcmd()
            exec "wincmd ="
        endif
        unlet t:vc_restore_win
        normal! ze
    endif
enddef
def ToggleWinMax()
    if exists('t:vc_restore_win') && t:vc_restore_win.after == winrestcmd()
        RestoreWin()
    elseif winnr('$') > 1
        MaximizeWin()
    endif
enddef
nnoremap <space>um <ScriptCmd>ToggleWinMax()<CR>
SetDesc('<space>um', 'Toggle Win Maximize')
augroup VcConfigKeymapRestoreMaximizeWinOnWinleave
    au!
    au WinLeave * RestoreWin()
augroup END
# }}}

# }}}

# tabs {{{
# vim-which-key only recognize <Tab>, no <tab>
SetGroup('<space><Tab>', 'tab')
nnoremap <space><Tab>f <Cmd>tabfirst<CR>
SetDesc('<space><Tab>f', 'First Tab')
nnoremap <space><Tab>l <Cmd>tablast<CR>
SetDesc('<space><Tab>l', 'Last Tab')
nnoremap <space><Tab>o <Cmd>tabonly<CR>
SetDesc('<space><Tab>o', 'Close Other Tabs')
nnoremap <space><Tab>n <Cmd>tabnew<CR>
SetDesc('<space><Tab>n', 'New Tab')
nnoremap <space><Tab>d <Cmd>tabclose<CR>
SetDesc('<space><Tab>d', 'Close Tab')
nnoremap [<Tab> <Cmd>tabprevious<CR>
SetDesc('[<Tab>', 'Prev Tab')
nnoremap ]<Tab> <Cmd>tabnext<CR>
SetDesc(']<Tab>', 'Next Tab')
# }}}
