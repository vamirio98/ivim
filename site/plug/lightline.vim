vim9script

import autoload "vc/util/keymap.vim"
import autoload "vc/util/notify.vim"
import autoload "vc/util/plug.vim"

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
      'vc_filename', 'modified',
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
  'vc_filename': 'g:VcFilename',
}
g:lightline.component_expand = {
  'buffers': 'lightline#bufferline#buffers',
  'rtabs': 'g:LightlineTabRight',
  'gutentags': "g:VcStlTags",
  'gitsummary': "g:VcStlGitSummary",
  #'lspdiag': 'g:VcStlLspDiag',
  'gitbranch': 'g:VcStlGitBranch',
  # 'coc_error': 'g:VcStlCocError',
  # 'coc_warn': 'g:VcStlCocWarn',
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
  hi! link VcStlA LightlineLeft_normal_0
  hi! link VcStlB LightlineLeft_normal_1
  hi! link VcStlC LightlineRight_normal_2
  hi! link VcStlX LightlineRight_normal_2
  hi! link VcStlY LightlineRight_normal_1
  hi! link VcStlZ LightlineRight_normal_0

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
def g:VcStlTags(): string
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
def g:VcFilename(): string
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
  NewHighlight('VcStlGitSumAdd', 'VcStlX', 'GitGutterAdd')
  NewHighlight('VcStlGitSumChange', 'VcStlX', 'GitGutterChange')
  NewHighlight('VcStlGitSumDelete', 'VcStlX', 'GitGutterDelete')
enddef

def g:VcStlGitSummary(): string
  var [a, m, r] = g:GitGutterGetHunkSummary()
  return printf('%s%s%s%s%s',
    (a == 0 ? '' : printf('%%#VcStlGitSumAdd#+%%(%d%%)%%*', a)),
    (m + r > 0 ? ' ' : ''),
    (m == 0 ? '' : printf('%%#VcStlGitSumChange#~%%(%d%%)%%*', m)),
    (m > 0 && r > 0 ? ' ' : ''),
    (r == 0 ? '' : printf('%%#VcStlGitSumDelete#-%%(%d%%)%%*', r))
  )
enddef
# }}}

# {{{ git branch
def SetupStlGitBranchColor(): void
  NewHighlight('VcStlGitBranch', 'VcStlB', 'Blue')
enddef
def g:VcStlGitBranch(): string
  if &ft == 'dirvish'
    return ''
  else
    var br = g:FugitiveHead()
    return len(br) == 0 ? '' :
      printf('%%#VcStlGitBranch# %%(%s%%)%%#VcStlB#', br)
  endif
enddef
# }}}

# {{{ lsp diag
def SetupStlLspDiagColor(): void
  NewHighlight('VcStlLspDiagError', 'VcStlB', 'Red')
  NewHighlight('VcStlLspDiagWarn', 'VcStlB', 'Yellow')
enddef
def g:VcStlLspDiag(): string
  if plug.Has('YouCompleteMe')
    var error = youcompleteme#GetErrorCount()
    var warn = youcompleteme#GetWarningCount()
    return printf('%s%s%s',
      (error == 0 ? '' :
        '%#VcStlLspDiagError# ' .. string(error) .. '%#VcStlB#'),
      (error > 0 && warn > 0 ? ' ' : ''),
      (warn == 0 ? '' :
        '%#VcStlLspDiagWarn# ' .. string(warn) .. '%#VcStlB#')
    )
  endif
enddef
# }}}

# {{{ coc-status
def g:VcStlCocError(): string
  var error_sign: string = get(g:, 'coc_status_error_sign', ' ')
  var info = get(b:, 'coc_diagnostic_info', {})
  var error_num: number = get(info, 'error', 0)
  return error_num == 0 ? '' : printf("%s%d", error_sign, error_num)
enddef
def g:VcStlCocWarn(): string
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

augroup vc_site_plug_lightline
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
      | notify.Error('cannot refresh bufferline') | endif
  endif
augroup END
