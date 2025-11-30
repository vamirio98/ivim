vim9script

import autoload "../../autoload/module/keymap.vim" as keymap

var SetGroup: func = keymap.SetGroup
var SetDesc: func = keymap.SetDesc
SetGroup('<leader>d', 'debug')

nmap <silent> <leader>db <Plug>VimspectorToggleBreakpoint
SetDesc('<leader>db', 'Toggle Breakpoint')
nmap <silent> <leader>dB <Plug>VimspectorToggleConditionalBreakpoint
SetDesc('<leader>dB', 'Toggle Cond Breakpoint')

nmap <silent> <leader>dc <Plug>VimspectorContinue
SetDesc('<leader>dc', 'Start/Continue')

nmap <silent> <leader>df <Plug>VimspectorAddFunctionBreakpoint
SetDesc('<leader>df', 'Toggle Func Breakpoint')

nmap <silent> <leader>dp <Plug>VimspectorPause
SetDesc('<leader>dp', 'Pause Debug')

nmap <silent> <leader>dr <Plug>VimspectorRestart
SetDesc('<leader>dr', 'Restart')

nmap <silent> <leader>ds <Plug>VimspectorStop
SetDesc('<leader>ds', 'Stop')

augroup ivim_vimspector
  au!
  au User VimSpectorUICreated CustomizeWinBar()
  au User VimSpectorJumpedToFrame OnJumpToFrame()
  au User VimSpectorDebugEnded ++nested OnDebugEnd()
augroup END

# customize UI {{{
def CustomizeWinBar(): void
  win_gotoid(g:vimspector_session_windows.code)
  # clear the existing WinBar create by vimspector
  aunmenu WinBar

  # create new WinBar
  nnoremenu WinBar.▷ <Cmd>call vimspector#Continue()<CR>
  nnoremenu WinBar.↷ <Cmd>call vimspector#StepOver()<CR>
  nnoremenu WinBar.↓ <Cmd>call vimspector#StepInto()<CR>
  nnoremenu WinBar.↑ <Cmd>call vimspector#StepOut()<CR>
  nnoremenu WinBar.● <Cmd>call vimspector#ToggleBreakpoint()<CR>
  nnoremenu WinBar.‖ <Cmd>call vimspector#Pause()<CR>
  nnoremenu WinBar.□ <Cmd>call vimspector#Stop()<CR>
  nnoremenu WinBar.⟲ <Cmd>call vimspector#Restart()<CR>
  nnoremenu WinBar.✕ <Cmd>call vimspector#Reset()<CR>
enddef
# }}}

# custom mappings while debuggins {{{
var s_buffers: dict<any> = {}
const MAPS = {
  '<F5>': '<Plug>VimSpectorContinue',
  '<F3>': '<Plug>VimspectorStop',
  '<localleader>b': '<Plug>VimspectorToggleBreakpoint',
  '<localleader>B': '<Plug>VimspectorBreakpoints',
  '<localleader>d': '<Plug>VimspectorDisassemble',
  '<localleader>i': '<Plug>VimspectorBalloonEval',
  '<localleader>J': '<Plug>VimspectorDownFrame',
  '<localleader>K': '<Plug>VimspectorUpFrame',
  '<localleader>j': '<Plug>VimspectorJumpToNextBreakpoint',
  '<localleader>k': '<Plug>VimspectorJumpToPreviousBreakpoint',
  '<localleader>p': '<Plug>VimspectorJumpToProgramCounter',
  '<localleader>r': '<Plug>VimspectorRunToCursor',
  '<localleader>R': '<Plug>VimspectorGoToCurrentLine',
  '<F10>': '<Plug>VimspectorStepOver',
  '<F11>': '<Plug>VimspectorStepInto',
  '<F12>': '<Plug>VimspectorStepOut',
}

def OnJumpToFrame(): void
  if has_key(s:buffers, string(bufnr()))
    return
  endif

  for [k, v] in items(MAPS)
    exec 'nmap <silent><buffer>' k v
  endfor

  s_buffers[string(bufnr())] = {'modifiable': &modifiable}
  setlocal nomodifiable
enddef

def OnDebugEnd(): void
  var orig_buf: number = bufnr()
  var hidden: bool = &hidden

  augroup ivim_vimspector_swap_exists
    au!
    au SwapExists * v:swapchoice = 'o'
  augroup END

  try
    set hidden
    for bufnr in keys(s_buffers)
      try
        exec 'buffer' bufnr
        for k in keys(MAPS)
          exec 'silent! nunmap <buffer>' k
        endfor
        let &modifiable = s_buffers[bufnr]['modifiable']
      finally
      endtry
    endfor
  finally
    exec 'noautocmd buffer' orig_buf
    &hidden = hidden
  endtry

  au! ivim_vimspector_swap_exists
  s_buffers = {}
enddef
# }}}
