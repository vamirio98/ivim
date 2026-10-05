vim9script

import autoload 'util/msg.vim' as mMsg
import autoload 'tool/option.vim' as mOption
import autoload 'tool/buffer.vim' as mBuffer

type Option = mOption.Option

# buffers {{{
# switch to other buffer
nnoremap <space>bb <Cmd>e #<CR>

# delete buffer
nnoremap <space>bd <ScriptCmd>mBuffer.Close()<CR>
# delete other buffers
nnoremap <space>bo <ScriptCmd>mBuffer.CloseOthers()<CR>
# delete buffer and window
nnoremap <space>bD <cmd>:bd<cr>
# }}}

# clear search on escape
# clear search, diff update and redraw, taken from runtime/lua/_editor.lua
nnoremap <space>ur <Cmd>noh<bar>diffupdate<bar>normal! <C-l><CR>

# new file
nnoremap <space>fn <Cmd>enew<CR>

# {{{ location list/ quickfix list
# location list
def ToggleLocList(): void
    var ll = getloclist(bufnr('%'))
    if len(ll) == 0
        mMsg.Warn('location list is empty')
        lclose
    else
        lopen
    endif
enddef
nnoremap <space>xl <ScriptCmd>ToggleLocList()<CR>

# quickfix list
def ToggleQfList(): void
    var qf = getqflist({'bufnr': bufnr('%')})
    if len(qf) == 0
        mMsg.Warn('quickfix list is empty')
        cclose
    else
        copen
    endif
enddef
nnoremap <space>xq <ScriptCmd>ToggleQfList()<CR>
# }}}

# {{{ option
var spell = Option.new('spell')
nnoremap <space>us <ScriptCmd>spell.Toggle()<CR>

var wrap = Option.new('wrap')
nnoremap <space>uw <ScriptCmd>wrap.Toggle()<CR>

var relativenumber = Option.new('relativenumber')
nnoremap <space>uL <ScriptCmd>relativenumber.Toggle()<CR>

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

var conceallevel = Option.newOnOff('conceallevel', (&cole > 0 ? &cole : 2), 0)
nnoremap <space>uc <ScriptCmd>conceallevel.Toggle()<CR>

var colorcolumn = Option.newOnOff('colorcolumn', (&cc == "" ? "81" : &cc), "")
nnoremap <space>uC <ScriptCmd>colorcolumn.Toggle()<CR>

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
# }}}

# }}}

def SourceVimrc(): void
    g:VcUnletExported()
    exec 'source %'
enddef
nnoremap <space>vs <ScriptCmd>SourceVimrc()<cr>

# windows {{{
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
augroup VcConfigKeymapRestoreMaximizeWinOnWinleave
    au!
    au WinLeave * RestoreWin()
augroup END
# }}}

# }}}

# tabs {{{
# vim-which-key only recognize <Tab>, no <tab>
nnoremap <space><Tab>f <Cmd>tabfirst<CR>
nnoremap <space><Tab>l <Cmd>tablast<CR>
nnoremap <space><Tab>o <Cmd>tabonly<CR>
nnoremap <space><Tab>n <Cmd>tabnew<CR>
nnoremap <space><Tab>d <Cmd>tabclose<CR>
nnoremap [<Tab> <Cmd>tabprevious<CR>
nnoremap ]<Tab> <Cmd>tabnext<CR>
# }}}
