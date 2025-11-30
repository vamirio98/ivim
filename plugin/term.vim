vim9script

import autoload "../autoload/term/term.vim" as term
import autoload "../autoload/lib/list.vim" as ilist

type ListNode = ilist.ListNode

g:ivim_term_shell = get(g:, 'ivim_term_shell', &shell)
g:ivim_term_autoclose = get(g:, 'ivim_term_autoclose', false)
g:ivim_term_width = get(g:, 'ivim_term_width', 0.6)
g:ivim_term_height = get(g:, 'ivim_term_height', 0.4)
g:ivim_term_title_pos = get(g:, 'ivim_term_title_pos', 'left')
g:ivim_term_win_type = get(g:, 'ivim_term_win_type', 'popup')
g:ivim_term_win_pos = get(g:, 'ivim_term_win_pos', 'botright')
g:ivim_term_borderchars = get(g:, 'ivim_term_borderchars', ['─', '│', '─', '│', '╭', '╮', '╯', '╰'])

type Term = term.Term

class Node
  var node: ListNode = ListNode.new()
  var i: number = 0

  def new(i: number)
    this.i = i
  enddef
endclass

# {{{ Test
def g:IvimTermTest(): void
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
