vim9script

import autoload 'vc/util/misc.vim' as mMisc

# Terminal style
g:floaterm_wintype = 'split'
g:floaterm_position = 'belowright'
g:floaterm_height = 0.4
g:floaterm_width = 0.5

# Close window if the job exits normally
g:floaterm_autoclose = 1
# Open or hide the floaterm window.
g:floaterm_keymap_toggle = '<M-=>'
# Open a new floaterm window.
g:floaterm_keymap_new = '<M-+>'
# Switch to the previous floaterm instance.
g:floaterm_keymap_prev = '<M-,>'
# Switch to the next floaterm instance
g:floaterm_keymap_next = '<M-.>'
# Close the current terminal instance.
g:floaterm_keymap_kill = '<M-->'

Plug 'voldikss/vim-floaterm'

# Kill all floaterm instance when quit vim.
augroup VcSitePlugFloaterm
  au!
  au QuitPre * exec 'FloatermKill!'
augroup END

Plug 'voldikss/vim-floaterm'

if mMisc.Executable('pwsh')
    g:floaterm_shell = 'pwsh'
endif
