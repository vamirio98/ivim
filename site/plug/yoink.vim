vim9script

import autoload "../../autoload/module/keymap.vim" as keymap

var SetGroup = keymap.SetGroup
var SetDesc = keymap.SetDesc

nmap <C-n> <plug>(YoinkPostPasteSwapBack)
nmap <C-p> <plug>(YoinkPostPasteSwapForward)

nmap p <plug>(YoinkPaste_p)
nmap P <plug>(YoinkPaste_P)
nmap gp <plug>(YoinkPaste_gp)
nmap gP <plug>(YoinkPaste_gP)

nmap [y <plug>(YoinkRotateBack)
nmap ]y <plug>(YoinkRotateForward)
SetDesc('[y', 'Rotate Back Yank History')
SetDesc(']y', 'Rotate Forward Yank History')
