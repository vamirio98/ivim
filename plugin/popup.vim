vim9script

import autoload '../autoload/lib/buffer.vim' as buffer
import autoload '../autoload/lib/popup/popup.vim' as popup

type Popup = popup.Popup

# {{{ Test
def g:IvimPopupTest()
  var b: number = buffer.Alloc()
  var p: Popup = Popup.new(b)
  var t: string = 'This popup will show 3 times, now is '
  var i: number = 1
  var j: number = 0
  buffer.Update(b, t .. i)
  p.Show()
  timer_start(1000, (_) => {
    if p.id == -1
      p.Show()
    else
      p.Hide()
      i = i + 1
      buffer.Update(b, t .. i)
    endif
    j = j + 1
    if j == 5
      buffer.Free(b)
    endif
  }, { 'repeat': 5 })
enddef
# }}}
