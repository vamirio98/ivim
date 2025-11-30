vim9script

export class ListNode
  public var prev: ListNode = this
  public var next: ListNode = this

  def new(prev: ListNode = this, next: ListNode = this)
    this.prev = prev
    this.next = next
  enddef
endclass

export def Empty(head: ListNode): bool
  return head.next == head
enddef

export def Insert(node: ListNode, head: ListNode): ListNode
  node.next = head.next
  node.prev = head
  head.next = node
  return node
enddef

export def Append(node: ListNode, head: ListNode): ListNode
  node.prev = head.prev
  node.next = head
  head.prev = node
  return node
enddef

export def Remove(node: ListNode): ListNode
  node.prev.next = node.next
  node.next.prev = node.prev
  node.prev = node
  node.next = node
  return node
enddef
