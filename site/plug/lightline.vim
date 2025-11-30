vim9script

import autoload "../../autoload/module/keymap.vim" as keymap
import autoload "../../autoload/lib/ui.vim" as ui
import autoload "../../autoload/module/plug.vim" as plug

# {{{ setting
set noshowmode
set laststatus=2
set hidden # allow buffer switching without saving
set showtabline=2

g:lightline#bufferline#filter_by_tabpage = 1
g:lightline#bufferline#enable_devicons = 1

def g:LightlineBufferlineFilter(buffer: number): bool
  return getbufvar(buffer, '&buftype') !=# 'terminal'
enddef

if !exists('g:lightline')
  g:lightline = {}
endif

g:lightline.subseparator = {'left': '|', 'right': '|'}
g:lightline.tabline_subseparator = g:lightline.subseparator

# tabs compoents
g:lightline.tab = { 'active': [ 'tabnum' ], 'inactive': [ 'tabnum' ] }

g:lightline#bufferline#buffer_filter = "g:LightlineBufferlineFilter"

g:lightline.colorscheme = 'gruvbox_material'

g:lightline.active = {
  'left': [ ['mode', 'paste'],
    [ 'gitbranch',
      # 'coc_error', 'coc_warn', 'lspdiag',
      # 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_infos',
      'ivim_filename', 'modified',
    ],
  ],
  'right': [ ['lineinfo'], ['percent'],
    ['gutentags', 'gitsummary', 'fileformat', 'filetype'],
  ]
}
g:lightline.tabline = {
  'left': [ ['buffers'] ],
  'right': [ ['rtabs'] ],
}

g:lightline.component_function = {
  'ivim_filename': 'g:IvimFilename',
}
g:lightline.component_expand = {
  'buffers': 'lightline#bufferline#buffers',
  'rtabs': 'g:LightlineTabRight',
  'gutentags': "g:IvimStlTags",
  'gitsummary': "g:IvimStlGitSummary",
  #'lspdiag': 'g:IvimStlLspDiag',
  'gitbranch': 'g:IvimStlGitBranch',
  # 'coc_error': 'g:IvimStlCocError',
  # 'coc_warn': 'g:IvimStlCocWarn',
  'linter_checking': 'lightline#ale#checking',
  'linter_infos': 'lightline#ale#infos',
  'linter_warnings': 'lightline#ale#warnings',
  'linter_errors': 'lightline#ale#errors',
}
g:lightline.component_type = {
  'buffers': 'tabsel',
  'rtabs': 'tabsel',
  'coc_error': 'error',
  'coc_warn': 'warning',
  'linter_checking': 'right',
  'linter_infos': 'right',
  'linter_warnings': 'warning',
  'linter_errors': 'error',
}
# }}}

# {{{ lightline-ale
g:lightline#ale#indicator_checking = " "
g:lightline#ale#indicator_infos = " "
g:lightline#ale#indicator_warnings = " "
g:lightline#ale#indicator_errors = " "
# }}}

# {{{ component utils
# {{{ setup color group
def SetupColor()
  hi! link IvimStlA LightlineLeft_normal_0
  hi! link IvimStlB LightlineLeft_normal_1
  hi! link IvimStlC LightlineRight_normal_2
  hi! link IvimStlX LightlineRight_normal_2
  hi! link IvimStlY LightlineRight_normal_1
  hi! link IvimStlZ LightlineRight_normal_0

  SetupStlGitSumColor()
  SetupStlLspDiagColor()
  SetupStlGitBranchColor()

  # change tabline color, see:
  # https://github.com/itchyny/lightline.vim/issues/508#issuecomment-694716949
  var palette = eval(printf("g:lightline#colorscheme#%s#palette",
    g:lightline.colorscheme))
  palette.tabline.right = palette.tabline.left
enddef

def NewHighlight(name: string, bg: string, fg: string): void
  var nbg: dict<any> = hlget(bg, 1)[0]
  var nfg: dict<any> = hlget(fg, 1)[0]
  exec printf('hi! %s ctermbg=%s ctermfg=%s guibg=%s guifg=%s',
    name, nbg.ctermbg, nfg.ctermfg, nbg.guibg, nfg.guifg)
enddef
def NewColor(bg: string, fg: string): list<string>
  var nbg: dict<any> = hlget(bg, 1)[0]
  var nfg: dict<any> = hlget(fg, 1)[0]
  return [ nfg.guifg, nbg.guibg, nfg.ctermfg, nbg.ctermbg ]
enddef
# }}}

# tags {{{ #
def g:IvimStlTags(): string
  return gutentags#statusline('[R] ', '', 'tags')
enddef
# }}} tags #

# {{{ tabs
# see: https://github.com/itchyny/lightline.vim/issues/440#issuecomment-610172628
def g:LightlineTabRight(): list<list<string>>
  return reverse(lightline#tabs())
enddef
# }}}

# {{{ filename
def g:IvimFilename(): string
  var fn = expand('%')
  if &ft == 'dirvish'
    return fn == '/' ? fn : fnamemodify(fn, ':h:t')
  else
    fn = fnamemodify(fn, ':t')
    fn = fn == '' ? "[No Name]" : fn
    return fn
  endif
enddef
# }}}

# {{{ git summary
def SetupStlGitSumColor(): void
  NewHighlight('IvimStlGitSumAdd', 'IvimStlX', 'GitGutterAdd')
  NewHighlight('IvimStlGitSumChange', 'IvimStlX', 'GitGutterChange')
  NewHighlight('IvimStlGitSumDelete', 'IvimStlX', 'GitGutterDelete')
enddef

def g:IvimStlGitSummary(): string
  var [a, m, r] = g:GitGutterGetHunkSummary()
  return printf('%s%s%s%s%s',
    (a == 0 ? '' : printf('%%#IvimStlGitSumAdd#+%%(%d%%)%%*', a)),
    (m + r > 0 ? ' ' : ''),
    (m == 0 ? '' : printf('%%#IvimStlGitSumChange#~%%(%d%%)%%*', m)),
    (m > 0 && r > 0 ? ' ' : ''),
    (r == 0 ? '' : printf('%%#IvimStlGitSumDelete#-%%(%d%%)%%*', r))
  )
enddef
# }}}

# {{{ git branch
def SetupStlGitBranchColor(): void
  NewHighlight('IvimStlGitBranch', 'IvimStlB', 'Blue')
enddef
def g:IvimStlGitBranch(): string
  if &ft == 'dirvish'
    return ''
  else
    var br = g:FugitiveHead()
    return len(br) == 0 ? '' :
      printf('%%#IvimStlGitBranch# %%(%s%%)%%#IvimStlB#', br)
  endif
enddef
# }}}

# {{{ lsp diag
def SetupStlLspDiagColor(): void
  NewHighlight('IvimStlLspDiagError', 'IvimStlB', 'Red')
  NewHighlight('IvimStlLspDiagWarn', 'IvimStlB', 'Yellow')
enddef
def g:IvimStlLspDiag(): string
  if plug.Has('YouCompleteMe')
    var error = youcompleteme#GetErrorCount()
    var warn = youcompleteme#GetWarningCount()
    return printf('%s%s%s',
      (error == 0 ? '' :
        '%#IvimStlLspDiagError# ' .. string(error) .. '%#IvimStlB#'),
      (error > 0 && warn > 0 ? ' ' : ''),
      (warn == 0 ? '' :
        '%#IvimStlLspDiagWarn# ' .. string(warn) .. '%#IvimStlB#')
    )
  endif
enddef
# }}}

# {{{ coc-status
def g:IvimStlCocError(): string
  var error_sign: string = get(g:, 'coc_status_error_sign', ' ')
  var info = get(b:, 'coc_diagnostic_info', {})
  var error_num: number = get(info, 'error', 0)
  return error_num == 0 ? '' : printf("%s%d", error_sign, error_num)
enddef
def g:IvimStlCocWarn(): string
  var warn_sign: string = get(g:, 'coc_status_warning_sign', ' ')
  var info = get(b:, 'coc_diagnostic_info', {})
  var warn_num: number = get(info, 'warning', 0)
  return warn_num == 0 ? '' : printf("%s%d", warn_sign, warn_num)
enddef
# }}}

# }}}

# {{{ keymap
var SetGroup: func = keymap.SetGroup
var SetDesc: func = keymap.SetDesc

nmap H <Plug>lightline#bufferline#go_previous()
nmap L <Plug>lightline#bufferline#go_next()
nmap [b <Plug>lightline#bufferline#go_previous()
nmap ]b <Plug>lightline#bufferline#go_next()

SetGroup('<leader>b', 'buffer')

nmap <leader>bH <Plug>lightline#bufferline#move_first()
SetDesc('<leader>bH', 'Reorder to First')
nmap <leader>bL <Plug>lightline#bufferline#move_last()
SetDesc('<leader>bL', 'Reorder to Last')

nmap <leader>bh <Plug>lightline#bufferline#move_previous()
SetDesc('<leader>bh', 'Reorder to Prev')
nmap <leader>bl <Plug>lightline#bufferline#move_next()
SetDesc('<leader>bl', 'Reorder to Next')

nmap <leader>br <Plug>lightline#bufferline#reset_order()
SetDesc('<leader>br', 'Reorder')
# }}}

augroup ivim_lightline
  au!
  # wait for colorscheme loaded
  au VimEnter * SetupColor()
  if plug.Has('coc.nvim')
    au User CocStatusChange lightline#update()
  endif
  if plug.Has('YouCompleteMe')
    au CursorHold * lightline#update()
  endif
  if plug.Has('vim-gutentags')
    au User GutentagsUpdating lightline#update()
    au User GutentagsUpdated lightline#update()
  endif
  au FileType dirvish lightline#update()
  au User GitGutter lightline#update()

  # update bufferline when buffer list change, or a deleted buffer may remain
  # in bufferline
  if has('timers')
    def ReloadBufline(timer: any)
      lightline#bufferline#reload()
    enddef
    au BufDelete * if timer_start(200, function('ReloadBufline')) == -1
      | ui.Error('cannot refresh bufferline') | endif
  endif
augroup END
