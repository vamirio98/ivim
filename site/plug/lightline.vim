vim9script

import autoload "util/msg.vim" as mMsg
import autoload 'util/path.vim' as mPath

import autoload 'tui/highlight.vim' as mHighlight


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
        [
            'vcProjectName',
            'gitBranch',
            'lspDiagError', 'lspDiagWarn',
            # 'lspDiagInfo', 'lspDiagHint',
            # 'cocError', 'cocWarn',
            'lspStatus',
            'vcFilename'
        ],
    ],
    'right': [ ['lineinfo'], ['percent'],
        ['gutentags', 'gitSummary', 'fileformat', 'filetype'],
    ]
}
g:lightline.tabline = {
    'left': [ ['buffers'] ],
    'right': [ ['rtabs'] ],
}

# g:lightline.component = {
# }

# update each time cursor move, and have no color, only functions that consume
# less performance can place here
g:lightline.component_function = {
}

# only update when lightline#update() called, any function that consume high
# performance should place in here
g:lightline.component_expand = {
    'buffers': 'lightline#bufferline#buffers',
    'rtabs': 'g:LightlineTabRight',
    'gutentags': "g:VcSlTags",
    'gitSummary': "g:VcSlGitSummary",
    'lspDiagError': 'g:VcSlLspDiagError',
    'lspDiagWarn': 'g:VcSlLspDiagWarn',
    'lspDiagInfo': 'g:VcSlLspDiagInfo',
    'lspDiagHint': 'g:VcSlLspDiagHint',
    'lspStatus': 'g:VcSlLspStatus',
    'gitBranch': 'g:VcSlGitBranch',
    'vcFilename': 'g:VcFilename',
    'vcProjectName': 'g:VcSlProjectName',
    # 'cocError': 'g:VcSlCocError',
    # 'cocWarn': 'g:VcSlCocWarn',
}

# specify the component_expand color
g:lightline.component_type = {
    'buffers': 'tabsel',
    'rtabs': 'tabsel',
    'cocError': 'error',
    'cocWarn': 'warning',
    'lspDiagError': 'error',
    'lspDiagWarn': 'warning',
}

# g:lightline.component_raw = {
# }

# }}}

# {{{ lightline-ale
g:lightline#ale#indicator_checking = " "
g:lightline#ale#indicator_infos = "󰋼 "
g:lightline#ale#indicator_warnings = " "
g:lightline#ale#indicator_errors = " "
# }}}

# {{{ component utils
# {{{ setup color group
def SetupColor()
    hi! link VcSlA LightlineLeft_normal_0
    hi! link VcSlB LightlineLeft_normal_1
    hi! link VcSlC LightlineRight_normal_2
    hi! link VcSlX LightlineRight_normal_2
    hi! link VcSlY LightlineRight_normal_1
    hi! link VcSlZ LightlineRight_normal_0

    SetupSlGitSumColor()
    SetupSlGitBranchColor()

    # change tabline color, see:
    # https://github.com/itchyny/lightline.vim/issues/508#issuecomment-694716949
    var palette = eval(printf("g:lightline#colorscheme#%s#palette",
        g:lightline.colorscheme))
    palette.tabline.right = palette.tabline.left
enddef
# }}}

# tags {{{ #
def g:VcSlTags(): string
    return gutentags#statusline('[R] ', '', 'tags')
enddef
# }}} tags #

# {{{ tabs
# see: https://github.com/itchyny/lightline.vim/issues/440#issuecomment-610172628
def g:LightlineTabRight(): list<list<string>>
    return reverse(lightline#tabs())
enddef
# }}}

# project name {{{ #
def g:VcSlProjectName(): string
    var name: string = g:VcProjectName()
    return empty(name) ? '' : $' {name}'
enddef
# }}} project name #

# {{{ filename
def g:VcFilename(): string
    var fn = expand('%')
    if &ft == 'dirvish'
        return mPath.IsSamefile(fn, mPath.Parent(fn)) ? fn : mPath.Name(fn)
    else
        fn = fnamemodify(fn, ':t')
        fn = fn == '' ? "[No Name]" : fn
        fn ..= &modified ? ' +' : (&modifiable ? '' : ' -')
        return fn
    endif
enddef
# }}}

# {{{ git summary
def SetupSlGitSumColor(): void
    'VcSlGitSumAdd'->mHighlight.Combine('GitGutterAdd', 'VcSlX')
    'VcSlGitSumChange'->mHighlight.Combine('GitGutterChange', 'VcSlX')
    'VcSlGitSumDelete'->mHighlight.Combine('GitGutterDelete', 'VcSlX')
enddef

def g:VcSlGitSummary(): string
    var [a, m, r] = g:GitGutterGetHunkSummary()
    return printf('%s%s%s%s%s',
        (a == 0 ? '' : printf('%%#VcSlGitSumAdd#+%%(%d%%)%%*', a)),
        (m + r > 0 ? ' ' : ''),
        (m == 0 ? '' : printf('%%#VcSlGitSumChange#~%%(%d%%)%%*', m)),
        (m > 0 && r > 0 ? ' ' : ''),
        (r == 0 ? '' : printf('%%#VcSlGitSumDelete#-%%(%d%%)%%*', r))
    )
enddef
# }}}

# {{{ git branch
def SetupSlGitBranchColor(): void
    'VcSlGitBranch'->mHighlight.Combine('Blue', 'VcSlB')
enddef
def g:VcSlGitBranch(): string
    if &ft == 'dirvish'
        return ''
    else
        var br = g:FugitiveHead()
        return len(br) == 0 ? '' :
            printf('%%#VcSlGitBranch# %%(%s%%)%%#VcSlB#', br)
    endif
enddef
# }}}

# {{{ lsp diag
def g:VcSlLspDiagError(): string
    const count = lsp#lsp#ErrorCount().Error
    return count == 0 ? '' : $'{count}'
enddef
def g:VcSlLspDiagWarn(): string
    const count = lsp#lsp#ErrorCount().Warn
    return count == 0 ? '' : $'{count}'
enddef
def g:VcSlLspDiagInfo(): string
    const count = lsp#lsp#ErrorCount().Info
    return count == 0 ? '' : $'{count}󰋼'
enddef
def g:VcSlLspDiagHint(): string
    const count = lsp#lsp#ErrorCount().Hint
    return count == 0 ? '' : $'{count}󰌵'
enddef
def g:VcSlLspStatus(): string
    if empty(g:LspProgress)
        return ''
    endif

    for info in values(g:LspProgress)
        var parts = []
        if !empty(info.title)
            parts->add(info.title)
        endif
        if info.percentage >= 0
            parts->add(info.percentage .. '%')
        endif
        return parts->join(' ')
    endfor
    return ''
enddef
# }}}

# {{{ coc-status
def g:VcSlCocError(): string
    var errorSign: string = get(g:, 'coc_status_error_sign', ' ')
    var info = get(b:, 'coc_diagnostic_info', {})
    var errorNum: number = get(info, 'error', 0)
    return errorNum == 0 ? '' : printf("%s%d", errorSign, errorNum)
enddef
def g:VcSlCocWarn(): string
    var warnSign: string = get(g:, 'coc_status_warning_sign', ' ')
    var info = get(b:, 'coc_diagnostic_info', {})
    var warnNum: number = get(info, 'warning', 0)
    return warnNum == 0 ? '' : printf("%s%d", warnSign, warnNum)
enddef
# }}}

# }}}

# {{{ keymap
nmap H <Plug>lightline#bufferline#go_previous()
nmap L <Plug>lightline#bufferline#go_next()
nmap [b <Plug>lightline#bufferline#go_previous()
nmap ]b <Plug>lightline#bufferline#go_next()


nmap <leader>bH <Plug>lightline#bufferline#move_first()
nmap <leader>bL <Plug>lightline#bufferline#move_last()

nmap <leader>bh <Plug>lightline#bufferline#move_previous()
nmap <leader>bl <Plug>lightline#bufferline#move_next()

nmap <leader>br <Plug>lightline#bufferline#reset_order()
# }}}

augroup VcSitePlugLightline
    au!
    # wait for colorscheme loaded
    au VimEnter * SetupColor()
    # if plug.Has('coc.nvim')
    #   au User CocStatusChange lightline#update()
    # endif
    # if plug.Has('vim-gutentags')
    #   au User GutentagsUpdating lightline#update()
    #   au User GutentagsUpdated lightline#update()
    # endif
    au FileType dirvish lightline#update()
    au User GitGutter lightline#update()

    # update bufferline when buffer list change, or a deleted buffer may remain
    # in bufferline
    if has('timers')
        def ReloadBufline(timer: any)
            lightline#bufferline#reload()
        enddef
        au BufDelete * if timer_start(200, function('ReloadBufline')) == -1
            | mMsg.Error('cannot refresh bufferline') | endif
    endif

    au User LspProgressUpdate lightline#update()
    au User VcProject lightline#update()
augroup END
