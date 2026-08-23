vim9script

import autoload "tool/plug.vim" as mPlug
import autoload "util/path.vim" as mPath

g:gruvbox_material_enable_italic = 1

# for better performance
g:gruvbox_material_better_performance = 1

# set contrast
g:gruvbox_material_background = "medium"

# highlight diagnostic virtual text
g:gruvbox_material_diagnostic_virtual_text = "colored"

g:gruvbox_material_enable_bold = 1

g:gruvbox_material_visual = "reverse"

g:gruvbox_material_ui_contrast = "low"

g:gruvbox_material_current_word = "high contrast background"

if has('termguicolors')
    set termguicolors
endif


augroup VcSitePlugGruvboxMaterial
    au!
    au VimEnter * Setup()
augroup END

def Setup(): void
    UpdateTheme()
    colorscheme gruvbox-material
enddef

# {{{ update colortheme for lightline
def UpdateTheme()
    if mPlug.Has('lightline.vim')
        var dstDir: string = '~/.vim/autoload/lightline/colorscheme/'
        if !isdirectory(dstDir)
            silent! mkdir(dstDir, 'p')
        endif

        var src: string = mPath.Joinpath(mPlug.PluginDir('gruvbox-material'),
            'autoload/lightline/colorscheme/gruvbox_material.vim')
        var dst: string = mPath.Joinpath(dstDir, 'gruvbox_material.vim')
        if !filereadable(dst)
            filecopy(src, dst)
        elseif getftime(src) > getftime(dst)
            delete(dst, 'f')
            filecopy(src, dst)
        endif
    endif
enddef
# }}}
