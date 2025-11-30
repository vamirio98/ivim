vim9script

import autoload "../lib/platform.vim" as platform
import autoload "../lib/popup/popup.vim" as popup

export class Term
  var bufnr: number
  var winnr: number = -1

  var shell: string
  var autoclose: bool
  var width: any
  var height: any
  var title: string  # TODO: string or func(?): string
  var title_pos: string
  var win_type: string
  var win_pos: string
  var borderchars: list<string>

  def new(option: dict<any> = null_dict)
    var opt: dict<any> = option == null ? deepcopy(option) : {}

    # TODO: check type
    this.shell = get(opt, 'shell', g:ivim_term_shell)
    this.autoclose = get(opt, 'autoclose', g:ivim_term_autoclose)
    this.width = get(opt, 'width', g:ivim_term_width)
    this.height = get(opt, 'height', g:ivim_term_height)
    this.title = get(opt, 'title', 'term')
    this.title_pos = get(opt, 'win_type', g:ivim_term_win_type)
    this.win_type = get(opt, 'win_type', g:ivim_term_win_type)
    this.win_pos = get(opt, 'win_pos', g:ivim_term_win_pos)
    this.borderchars = get(opt, 'borderchars', g:ivim_term_borderchars)

    this.bufnr = term_start(this.shell, { 'hidden': 1 })
  enddef

  def _GenPopupOpt(): dict<any>
    var opt: dict<any> = {}

    var width = type(this.width) == v:t_number ? this.width : float2nr(this.width * &columns)
    var height = type(this.height) == v:t_number ? this.height : float2nr(this.height * &lines)
    opt.minwidth = width
    opt.maxwidth = width
    opt.minheight = height
    opt.maxheight = height
    opt.pos = this.win_pos
    opt.borderchars = this.borderchars

    return opt
  enddef

  def Show(): void
    if this.win_type == 'popup'
      if this.winnr == -1
        this.winnr = popup.Create(this.bufnr, this._GenPopupOpt())
      endif
      popup_show(this.winnr)
    endif
  enddef

  def Hide(): void
    if this.win_type == 'popup' && this.winnr != -1
      popup_close(this.winnr)
      this.winnr = -1
    endif
  enddef
endclass
