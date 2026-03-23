vim9script

import autoload 'vc/tui/highlight.vim' as vhl

# TODO: support multi style border chars, get them from a function
g:vcTuiBorderChars = get(g:, 'vcTuiBorderChars', ['─', '│', '─', '│', '╭', '╮', '╯', '╰'])

hi! link VcNormal Pmenu
hi! link VcSel CurSearch
vhl.Extend('VcKey', 'VcNormal', 'underline')
vhl.Extend('VcDisable', 'Comment', {'italic': false})
vhl.Extend('VcHelp', 'String')
