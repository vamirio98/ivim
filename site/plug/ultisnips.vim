vim9script

# all directories in vim runtimepath whose name is as follow will be search
# for snippet
g:UltiSnipsSnippetDirectories = ["UltiSnips"]
# add site to runtimepath so that UltiSnips can recognize the snippets
exec printf("set runtimepath+=%s/site", g:ivim_home)

g:UltiSnipsEditSplit = "horizontal"

# keymap
g:UltiSnipsExpandTrigger = "<C-J>"
g:UltiSnipsJumpForwardTrigger = "<C-J>"
g:UltiSnipsJumpBackwardTrigger = "<C-K>"
g:UltiSnipsListSnippets = "<C-X><C-X>"
