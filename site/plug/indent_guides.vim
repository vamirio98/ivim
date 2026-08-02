vim9script

import autoload "vc/util/string.vim" as str
import autoload "vc/util/keymap.vim"

g:vcIndentGuideEnabled = get(g:, 'vcIndentGuideEnabled', 1)

g:indent_guides_default_mapping = 0
g:indent_guides_guide_size = 0
g:indent_guides_start_level = 1
g:indent_guides_enable_on_vim_startup = g:vcIndentGuideEnabled
g:indent_guides_exclude_buftype = 0
g:indent_guides_exclude_filetypes = ['help', 'startify', 'nerdtree']
g:indent_guides_tab_guides = 1

Plug 'preservim/vim-indent-guides'

# {{{ keymap
def StripListchars(listchars: string): string
    var lc: string = listchars
    if str.Contains(lc, 'tab:')
        lc = substitute(lc, '\vtab:.{-},', 'tab:\\ \\ ,', '')
    endif
    if str.Contains(lc, 'lead:')
        lc = substitute(lc, 'lead:.{-},', 'lead:\\ ,', '')
    endif
    return lc
enddef
def VcIndentGuidesEnable(): void
    g:vcIndentGuideEnabled = 1
    exec 'IndentGuidesEnable'
    exec 'set listchars=' .. StripListchars(g:vc_listchars)
enddef
def VcIndentGuidesDisable(): void
    g:vcIndentGuideEnabled = 0
    exec 'IndentGuidesDisable'
    exec 'set listchars=' .. g:vc_listchars
enddef
def g:ToggleIndentGuides(): void
    if g:vcIndentGuideEnabled
        VcIndentGuidesDisable()
    else
        VcIndentGuidesEnable()
    endif
enddef

keymap.SetGroup('<leader>u', 'ui')
keymap.SetDesc('<leader>ui', 'Toggle Indent Guides')
nnoremap <leader>ui <Cmd>call g:ToggleIndentGuides()<CR>
# }}}

g:indent_guides_auto_colors = 0
augroup vc_site_plug_indent_guides
    au!
    au VimEnter,ColorScheme * :hi link IndentGuidesOdd DiffAdd
    au VimEnter,ColorScheme * :hi link IndentGuidesEven ToolbarLine
    au VimEnter * if g:vcIndentGuideEnabled
        | VcIndentGuidesEnable() | endif
augroup END
