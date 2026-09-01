vim9script

import autoload 'tui/highlight.vim' as mHighlight

# TODO: support multi style border chars, get them from a function
g:vcTuiBorderChars = get(g:, 'vcTuiBorderChars', ['─', '│', '─', '│', '╭', '╮', '╯', '╰'])

hi! link VcTuiNormal Pmenu
hi! link VcTuiSel PmenuSel
mHighlight.Extend('VcTuiKey', 'Title', 'bold')
mHighlight.Extend('VcTuiDisable', 'Comment', {'italic': false})
mHighlight.Extend('VcTuiHelp', 'String')
