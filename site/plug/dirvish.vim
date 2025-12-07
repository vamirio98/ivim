vim9script

import autoload 'vc/util/notify.vim'

g:vc_dirvish_hide_dotfile = get(g:, 'vc_dirvish_hide_dotfile', 1)

# sort and hide files, then locate related file
def SetupDirvish()
  # NOTE: because vim only remember location of a buffer when leave it,
  # if the buffer content changed, the cursor will stay in another file
  # when reenter the same buffer. e.g., toggle hide dot-file or files in
  # a directory have changed
  b:cur_file = get(b:, 'cur_file', getline('.'))
  if g:vc_dirvish_hide_dotfile
    exec 'silent! keeppatterns g@\v[\/]\.[^\/]+[\/]?$@d _'
    # add current file again if it's dotfile
    if match(b:cur_file, '\v[\/]\.[^\/]+[\/]?$') >= 0
      setline(line('$') + 1, b:cur_file)
    endif
  endif
  # sort filename
  exec 'sort ,^.*[\/],'
  var cur_file: string = escape(b:cur_file, '.*[]~\')
  # locate to current file
  search(cur_file, 'wc')

  nnoremap <silent><buffer> gh <ScriptCmd>ToggleHideDotfile()<CR>
enddef

def ToggleHideDotfile()
  g:vc_dirvish_hide_dotfile = !g:vc_dirvish_hide_dotfile
  notify.Info(printf('%s dot files', g:vc_dirvish_hide_dotfile ? 'Hide' : 'Show'))
  exec 'Dirvish'
enddef

augroup vc_site_plug_dirvish
  au!
  au FileType dirvish SetupDirvish()
  au BufLeave * if &ft == 'dirvish' && exists('b:cur_file')
    | unlet b:cur_file | endif
augroup END
