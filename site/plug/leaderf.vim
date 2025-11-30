vim9script

import autoload "../../autoload/lib/path.vim" as path
import autoload "../../autoload/lib/project.vim" as project
import autoload "../../autoload/module/plug.vim" as plug
import autoload "../../autoload/module/keymap.vim" as keymap

g:Lf_ShortcutF = ''
g:Lf_ShortcutB = ''

g:Lf_WildIgnore = {
  'dir': g:ivim_rootmarkers,
  'file': ['*.sw?', '~$*', '*.bak', '*.exe', '*.o', '*.so', '*.py[co]']
}

g:Lf_StlSeparator = { 'left': '', 'right': '', 'font': '' }
g:Lf_RootMarkers = g:ivim_rootmarkers
g:Lf_CommandMap = {}
# g:Lf_NormalCommandMap = { '*': { '<F1>': 'g?' } }
g:Lf_HideHelp = 1
g:Lf_RecurseSubmodules = 1 # only work with git 2.11+
g:Lf_ReverseOrder = 0
g:Lf_HistoryExclude = {
  'cmd': ['^w!?', '^q!?', '^.\s*$'],
  'search': ['^Plug']
}
g:Lf_UseVersionControlTool = 0
g:Lf_IgnoreCurrentBufferName = 1
g:Lf_ShowHidden = 1

# {{{ hide help file in MRU
g:Lf_MruFileExclude = get(g:, 'Lf_MruFileExclude', [])
for plugin in values(g:plugs)
  var plug_dir: string = plugin.dir
  var doc: string = path.Join(plug_dir, 'doc', '*')
  g:Lf_MruFileExclude += [doc]
endfor
# }}}

# vim-gutentags integration {{{
if plug.Has('vim-gutentags')
  g:Lf_GtagsGutentags = 1
  g:Lf_CacheDirectory = g:ivim_cache_dir
  var tag_cache_dir: string = path.Join(g:Lf_CacheDirectory, "LeaderF", "gtags")
  # FIXME: cmd.exe can _NOT_ handle '\\' in file path
  tag_cache_dir = substitute(tag_cache_dir, '\\\\', '\\', 'g')
  if !isdirectory(tag_cache_dir)
    silent! mkdir(tag_cache_dir, 'p')
  endif
  # set dir to save the tag file
  g:gutentags_cache_dir = tag_cache_dir
endif
# }}}

# {{{ keymap
var SetGroup: func = keymap.SetGroup
var SetDesc: func = keymap.SetDesc

# {{{ file
SetGroup('<leader>f', 'file')

def SearchFileInVimcfg()
  exec 'LeaderfFile' g:ivim_home
enddef
def LiveSearchVimcfg(): void
  exec 'Leaderf rg --live --no-fixed-string' g:ivim_home
enddef
nnoremap <leader>fc <ScriptCmd>SearchFileInVimcfg()<CR>
SetDesc('<leader>fc', 'Search Config File')
nnoremap <leader>fC <ScriptCmd>LiveSearchVimcfg()<CR>
SetDesc('<leader>fC', 'Live Search Config')

def SearchFileInProject()
  var root = project.GetRoot('.')
  exec 'LeaderfFile' root
enddef
nnoremap <leader>ff <ScriptCmd>SearchFileInProject()<CR>
SetDesc('<leader>ff', 'Search File (Project Root)')
nnoremap <leader>fF <Cmd>LeaderfFile .<CR>
SetDesc('<leader>fF', 'Search File (Cwd)')

nnoremap <leader>fr <Cmd>LeaderfMru<CR>
SetDesc('<leader>fr', 'Recent File')
nnoremap <leader>fR <Cmd>LeaderfMruCwd<CR>
SetDesc('<leader>fR', 'Recent File (Cwd)')
# }}}

# gtags {{{
SetGroup('<leader>G', 'gtags')
nmap <leader>Gd <Plug>LeaderfGtagsDefinition
SetDesc('<leader>Gd', 'Gtags Definition')
nmap <leader>Gg <Plug>LeaderfGtagsGrep
SetDesc('<leader>Gg', 'Gtags Word')
nmap <leader>Gr <Plug>LeaderfGtagsReference
SetDesc('<leader>Gr', 'Gtags Reference')
nmap <leader>Gs <Plug>LeaderfGtagsSymbol
SetDesc('<leader>Gs', 'Gtags Symbol')
# }}}

# {{{ search
SetGroup('<leader>s', 'search')

nnoremap <leader>sb <Cmd>LeaderfBuffer<CR>
SetDesc('<leader>sb', 'Buffer')

nnoremap <leader>sc <Cmd>LeaderfHistoryCmd<CR>
SetDesc('<leader>sc', 'Command History')

nnoremap <leader>sh <Cmd>LeaderfHelp<CR>
SetDesc('<leader>sh', 'Help Tag')

nnoremap <leader>sj <Cmd>Leaderf jumps<CR>
SetDesc('<leader>sj', 'Jump List')

nnoremap <leader>sk <Cmd>LeaderfMap<CR>
SetDesc('<leader>sk', 'Keymap')

nnoremap <leader>sl <Cmd>LeaderfLocList<CR>
SetDesc('<leader>sl', 'Location List')
nnoremap <leader>sL <Cmd>LeaderfSelf<CR>
SetDesc('<leader>sL', 'Leaderf Command')

nnoremap <leader>sm <Cmd>LeaderfMark<CR>
SetDesc('<leader>sm', 'Mark')

nnoremap <leader>sq <Cmd>LeaderfQuickFix<CR>
SetDesc('<leader>sq', 'Quickfix')

nnoremap <leader>sf <Cmd>LeaderfFunction<CR>
SetDesc('<leader>sf', 'Function (Current File)')

nnoremap <leader>st <Cmd>LeaderfBufTag<CR>
SetDesc('<leader>st', 'Tag (Current File)')
nnoremap <leader>sT <Cmd>LeaderfTag<CR>
SetDesc('<leader>sT', 'Tag (Workspace)')

nnoremap <leader>s: <Cmd>LeaderfCommand<CR>
SetDesc('<leader>s:', 'Command')
nnoremap <leader>s/ <Cmd>LeaderfHistorySearch<CR>
SetDesc('<leader>s/', 'Search History')
def LiveSearchInRoot(): void
  var root: string = project.CurRoot()
  exec 'Leaderf rg --live --no-fixed-string' root
enddef
nnoremap <leader>/ <ScriptCmd>LiveSearchInRoot()<CR>
SetDesc('<leader>/', 'Live Search (Root)')
# }}}

# }}}
