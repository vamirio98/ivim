vim9script

# all directories in vim runtimepath whose name is as follow will be search
# for snippet
g:UltiSnipsSnippetDirectories = ["UltiSnips"]
# add site to runtimepath so that UltiSnips can recognize the snippets
exec $'set runtimepath+={g:vc_home}/site'

g:UltiSnipsEditSplit = "horizontal"

# keymap
g:UltiSnipsExpandTrigger = "<C-J>"
g:UltiSnipsJumpForwardTrigger = "<C-J>"
g:UltiSnipsJumpBackwardTrigger = "<C-K>"
g:UltiSnipsListSnippets = "<C-X><C-X>"

Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
