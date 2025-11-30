vim9script

import autoload "../../autoload/lib/ui.vim" as ui
import autoload "../../autoload/lib/path.vim" as path
import autoload "../../autoload/module/plug.vim" as plug

# do NOT append default markers
g:gutentags_add_default_project_roots = 0

# set root dir of a project
g:gutentags_project_root = get(g:, 'ivim_rootmarkers',
  ['.root', '.svn', '.hg', '.git', '.project'])

# set ctags file name
g:gutentags_ctas_tagfile = 'tags'

# if has LeaderF, set tags directory by LeaderF
if !plug.Has('LeaderF')
  # detect dir ~/.cache/tags, create new one if it doesn't exist
  var tag_cache_dir: string = path.Join(g:ivim_cache_dir, 'tags')
  if !isdirectory(tag_cache_dir)
    silent! mkdir(tag_cache_dir, 'p')
  endif
  # set dir to save the tag file
  g:gutentags_cache_dir = tag_cache_dir
endif

# uncomment this for dubug
# g:gutentags_trace = 1

# use a ctags-compatible program to generate a tags file and
# GNU's gtags to generate a code database file
g:gutentags_modules = []
if executable('ctags')
  g:gutentags_modules += ['ctags']
endif
if executable('gtags-cscope') && executable('gtags')
  g:gutentags_modules += ['gtags_cscope']
endif
if empty(g:gutentags_modules)
  ui.Error('No ctags/gtags found')
endif

# set ctags arguments
g:gutentags_ctags_extra_args = ['--fields=+niazS', '--extras=+q']
g:gutentags_ctags_extra_args += ['--c++-kinds=+px']
g:gutentags_ctags_extra_args += ['--c-kinds=+px']

# use universal-ctags
g:gutentags_ctags_extra_args += ['--output-format=e-ctags']

# config gutentags whitelist
g:gutentags_exclude_filetypes = ['text']

# prevent gutentags from autoloading gtags database
g:gutentags_auto_add_gtags_cscope = 0

# change focus to quickfix window after search
g:gutentags_plus_switch = 1

g:gutentags_plus_nomap = 1
