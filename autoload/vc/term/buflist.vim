vim9script

export class ListNode
  var bufnr: number
  public var prev: ListNode
  public var next: ListNode

  def new(this.bufnr)
  enddef

  def ToString(): string
    return string(this.bufnr)
  enddef

  def IsValid(): bool
    return bufexists(this.bufnr)
  enddef
endclass

class List
  var head: ListNode
  var curr: ListNode
  var size: number

  def new()
    this.head = ListNode.new(-1)
    this.size = 0
    this.curr = head.next
  enddef

  def Append(node: ListNode): void
    if this.Empty()
      this.curr = node
    endif
    node.next = s_buflist.head
    node.prev = s_buflist.head.prev
    this.head.prev = node
    this.size += 1
    # always switch to the new terminal
    this.curr = node
  enddef

  # return `true` when succeed or `false`
  def Remove(node: ListNode): bool
    if this.Empty() || node == head
      return false
    endif
    if node.IsValid()
      exec node.bufnr .. 'bdelete!'
    endif
    if this.curr == node
      this.curr = node.next
    endif
    node.next.prev = node.prev
    node.prev.next = node.next
    node.prev = node
    node.next = node
    this.size -= 1
    return true
  enddef

  def Empty(): bool
    return this.head.next == this.head
  enddef

  # return the current buffer number or -1
  def Curr(): number
    if this.Empty()
      return -1
    endif
    return curr.bufnr
  enddef


endclass

var s_buflist = List.new()

export def Add(bufnr: number): void
  var node = ListNode.new(bufnr)
  s_buflist.Insert(node)
enddef


#===============================================================
# unit test
#===============================================================
def Test(): void
  var list = List.new()
  var n1 = ListNode.new(1)
  list.Insert(n1)
enddef

Test()
