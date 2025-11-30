vim9script

import autoload '../autoload/lib/buffer.vim' as buffer
import autoload '../autoload/lib/popup/popup.vim' as popup

# {{{ Test
def g:IvimPopupTest()
  var b: number = buffer.Alloc()
  var p: number = popup.Create(b)
  var t: string = 'This popup will show 3 times, now is '
  var i: number = 1
  var j: number = 0
  var shown: bool = true
  buffer.Update(b, t .. i)
  timer_start(1000, (_) => {
    if !shown
      popup_show(p)
      shown = true
    else
      popup_hide(p)
      shown = false
      i = i + 1
      buffer.Update(b, t .. i)
    endif
    j = j + 1
    if j == 5
      buffer.Free(b)
      popup_close(p)
    endif
  }, { 'repeat': 5 })
enddef
# }}}
