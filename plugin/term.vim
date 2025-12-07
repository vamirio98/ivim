vim9script

import autoload "vc/term/term.vim"
import autoload "vc/util/list.vim" as ilist

type ListNode = ilist.ListNode

g:vc_term_shell = get(g:, 'vc_term_shell', &shell)
g:vc_term_autoclose = get(g:, 'vc_term_autoclose', false)
g:vc_term_width = get(g:, 'vc_term_width', 0.6)
g:vc_term_height = get(g:, 'vc_term_height', 0.4)
g:vc_term_title_pos = get(g:, 'vc_term_title_pos', 'left')
g:vc_term_win_type = get(g:, 'vc_term_win_type', 'popup')
g:vc_term_win_pos = get(g:, 'vc_term_win_pos', 'botright')
g:vc_term_borderchars = get(g:, 'vc_term_borderchars', ['─', '│', '─', '│', '╭', '╮', '╯', '╰'])

type Term = term.Term

class Node
  var node: ListNode = ListNode.new()
  var i: number = 0

  def new(i: number)
    this.i = i
  enddef
endclass

# {{{ Test
def g:VcTermTest(): void
  var t = Term.new()
  t.Show()
  timer_start(3000, (_) => {
    t.Hide()
  })
  var head = ListNode.new()
  var n1 = Node.new(1)
  var n2 = Node.new(2)

  def P(n: Node): void
    echo n.i
  enddef

  ilist.Insert(n1, head)
  ilist.Foreach<Node>(head, P)
enddef
# }}}
