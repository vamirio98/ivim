vim9script


# Keymap {{{ #
# default keymap
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
    # 'j': 'DOWN',
    # 'k': 'UP',
    # 'h': 'LEFT',
    # 'l': 'RIGHT',
    'g': 'TOP',
    'G': 'BOTTOM',
    'q': 'ESC',
    'n': 'NEXT',
    'N': 'PREV',
}

export def Keymap(): dict<string>
    return deepcopy(kKeymap)
enddef
# }}} Keymap #
