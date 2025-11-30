vim9script

import autoload "../../autoload/module/plug.vim" as plug
import autoload "../../autoload/lib/path.vim" as path

g:gruvbox_material_enable_italic = 1

# for better performance
g:gruvbox_material_better_performance = 1

# set contrast
g:gruvbox_material_background = "medium"

# highlight diagnostic virtual text
g:gruvbox_material_diagnostic_virtual_text = "colored"

g:gruvbox_material_enable_bold = 1

g:gruvbox_material_visual = "reverse"

g:gruvbox_material_ui_contrast = "high"

g:gruvbox_material_current_word = "high contrast background"

if has('termguicolors')
  set termguicolors
endif

# {{{ update colortheme for lightline
def UpdateTheme()
  if plug.Has('lightline.vim')
    var dst_dir: string = path.Abspath('~/.vim/autoload/lightline/colorscheme/')
    if !isdirectory(dst_dir)
      silent! mkdir(dst_dir, 'p')
    endif

    var src: string = path.Join(plug.PluginDir('gruvbox-material'),
      'autoload/lightline/colorscheme/gruvbox_material.vim')
    var dst: string = path.Join(dst_dir, 'gruvbox_material.vim')
    if !filereadable(dst)
      filecopy(src, dst)
    elseif getftime(src) > getftime(dst)
      delete(dst, 'f')
      filecopy(src, dst)
    endif
  endif
enddef
UpdateTheme()
# }}}

colorscheme gruvbox-material
