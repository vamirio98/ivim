vim9script


# Object {{{ #
export def ObjMgr(): dict<any>
    if !exists('t:_vcTuiObj')
        t:_vcTuiObj = {}
    endif
    return t:_vcTuiObj
enddef


# Get window object
export def ObjAcquire(winid: number): dict<any>
    var mgr = ObjMgr()
    if !mgr->has_key(winid)
        mgr[winid] = {}
    endif
    return mgr[winid]
enddef


# Free window object
export def ObjRelease(winid: number): void
    var mgr = ObjMgr()
    if mgr->has_key(winid)
        mgr->remove(winid)
    endif
enddef
# }}} Object #


# Keymap. {{{ #
# Default keymap
const kKeymap: dict<string> = {
    "\<esc>": 'ESC',
    "\<cr>": 'ENTER',
    "\<space>": 'ENTER',
    "\<up>": 'UP',
    "\<down>": 'DOWN',
    "\<left>": 'LEFT',
    "\<right>": 'RIGHT',
    "\<home>": 'HOME',
    "\<end>": 'END',
    "\<C-j>": 'DOWN',
    "\<C-h>": 'LEFT',
    "\<C-k>": 'UP',
    "\<C-l>": 'RIGHT',
    "\<C-n>": 'NEXT',
    "\<C-p>": 'PREV',
    "\<C-b>": 'PAGEUP',
    "\<C-f>": 'PAGEDOWN',
    "\<C-u>": 'HALFUP',
    "\<C-d>": 'HALFDOWN',
    "\<PageUp>": 'PAGEUP',
    "\<PageDown>": 'PAGEDOWN',
    #"\<C-g>": 'NOHL',
    'j': 'DOWN',
    'k': 'UP',
    'h': 'LEFT',
    'l': 'RIGHT',
    'g': 'TOP',
    'G': 'BOTTOM',
    'q': 'ESC',
    'n': 'NEXT',
    'N': 'PREV',
}

export def Keymap(modifiable: bool = false): dict<string>
    return modifiable ? deepcopy(kKeymap) : kKeymap
enddef
# }}} Keymap. #


# Highlight {{{ #
export def HlClearCmd(): string
    return 'syn clear'
enddef

export def HlRegionCmd(color: string, row1: number, col1: number,
        row2: number, col2: number, virtcol: bool = false): string
    var colMode = virtcol ? 'v' : 'c'
    var cmd = $'syn region {color} '
    cmd ..= $'start=/\%{row1}l\%{col1}{colMode}/ '
    cmd ..= $'end=/\%{row2}l\%{col2}{colMode}/'
    return cmd
enddef
# }}} Highlight #
