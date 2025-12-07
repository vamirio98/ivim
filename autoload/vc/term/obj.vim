vim9script

export class TermObj
  var command: string

  var width: any
  var height: any
  var title: string  # TODO: string or func(?): string
  var title_pos: string
  var win_type: string
  var win_pos: string
  var borderchars: list<string>

  var bufnr: number

  def new(option: dict<any> = null_dict)
    var opt: dict<any> = option == null ? {} : deepcopy(option)

    this.width = get(opt, 'width', g:ivim_term_width)
    this.height = get(opt, 'height', g:ivim_term_height)
    this.title = get(opt, 'title', '')
    this.title_pos = get(opt, 'win_type', g:ivim_term_win_type)
    this.win_type = get(opt, 'win_type', g:ivim_term_win_type)
    this.win_pos = get(opt, 'win_pos', g:ivim_term_win_pos)
    this.borderchars = get(opt, 'borderchars', g:ivim_term_borderchars)

    var shell = get(g:, 'ivim_term_shell', &shell)
    this.bufnr = term_start(shell, { 'hidden': 1 })
    if this.bufnr == 0
      throw "Ivim: failed to create terminal"
    endif
    setbufvar(this.bufnr, 'ivim_term', this)
  enddef

  def ToString(): string
    return string(this.bufnr)
  enddef
endclass
