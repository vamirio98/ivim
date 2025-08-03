vim9script

import autoload '../autoload/lib/popup/popup.vim' as popup
type Popup = popup.Popup

def g:IvimPopupTest()
  var p: Popup = Popup.new('hello world')
  p.Show()
  timer_start(1000, (_) => {
    if p.id == -1
      p.Show()
    else
      p.Hide()
    endif
  }, { 'repeat': 3 })
enddef
