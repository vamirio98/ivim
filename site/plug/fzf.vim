vim9script

import autoload "../../autoload/module/keymap.vim" as keymap
import autoload "../../autoload/lib/project.vim" as project

g:fzf_vim = get(g:, 'fzf_vim', {})

g:fzf_layout = { 'down': '30%' }
# toggle preview window with <Ctrl-/>, show preview window on the right with
# 50% width, but if the width is smaller than 70 columns, it will show above
# the candidate list
g:fzf_vim.preview_window = [ 'right,50%,<70(up,40%)', 'ctrl-/' ]

# {{{ keymaps
var SetGroup: func = keymap.SetGroup
var SetDesc: func = keymap.SetDesc

SetGroup('<leader>f', 'file')

def SearchFileInVimcfg(): void
  exec 'Files' g:ivim_home
enddef
def LiveSearchVimcfg(): void
  exec 'RG .*' g:ivim_home
enddef
nnoremap <leader>fc <ScriptCmd>SearchFileInVimcfg()<CR>
SetDesc('<leader>fc', 'Search Config File')
#nnoremap <leader>fC <ScriptCmd>LiveSearchVimcfg()<CR>
#SetDesc('<leader>fC', 'Live Search Config')

def SearchFileInProject()
  var root: string = project.CurRoot()
  exec 'Files' root
enddef
nnoremap <leader>ff <ScriptCmd>SearchFileInProject()<CR>
SetDesc('<leader>ff', 'Search File (Project Root)')
nnoremap <leader>fF <Cmd>Files .<CR>
SetDesc('<leader>fF', 'Search File (Cwd)')

# TODO: MRU

# TODO: gtags

# {{{ search
SetGroup('<leader>s', 'search')

nnoremap <leader>sb' <Cmd>Buffers<CR>
SetDesc('<leader>sb', 'Buffer')

nnoremap <leader>sc <Cmd>History:<CR>
SetDesc('<leader>sc', 'Command History')

nnoremap <leader>sh <Cmd>Helptags<CR>
SetDesc('<leader>sh', 'Help Tag')

nnoremap <leader>sj <Cmd>Jumps<CR>
SetDesc('<leader>sj', 'Jump List')

# TODO: search all keymaps not only normal mode
nnoremap <leader>sk <Cmd>Maps<CR>
SetDesc('<leader>sk', 'Keymap')

nnoremap <leader>sm <Cmd>Marks<CR>
SetDesc('<leader>sm', 'Mark')

nnoremap <leader>st <Cmd>BTags<CR>
SetDesc('<leader>st', 'Tag (Current File)')
nnoremap <leader>sT <Cmd>Tags<CR>
SetDesc('<leader>sT', 'Tag (Workspace)')
# }}}
# }}}
