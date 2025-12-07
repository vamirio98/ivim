vim9script

import autoload "./obj.vim" as termobj

type TermObj = termobj.TermObj

# {{{ list
class Node
  public var prev: Node
  public var next: Node
  public var obj: any

  def new(this.obj)
    this.prev = this
    this.next = this
  enddef
endclass

class List
  var head: Node
  var curr: Node
  var index: number  # current node index, 0 means the list is empty
  var size: number

  def new()
    this.head = Node.new(null)
    this.curr = this.head
    this.index = 0
    this.size = 0
  enddef

  def Empty(): bool
    return this.head.next == this.head
  enddef

  def First(): Node
    return this.head.next
  enddef

  def Last(): Node
    return this.head.prev
  enddef

  # should be called after each time remove a node
  def _Reindex(): void
    if this.Empty()
      this.index = 0
      return
    endif
    var node: Node = this.head.next
    this.index = 1
    while node != this.curr && node != this.head
      node = node.next
      this.index += 1
    endwhile
    # can not found current node, may be something wrong
    if node == this.head
      this.index = 0
      throw "can not found current node"
    endif
  enddef

  def Add(node: Node): number
    node.next = this.head
    node.prev = this.head.prev
    this.head.prev.next = node
    this.head.prev = node

    # always index to the newest node after add it
    this.size += 1
    this.curr = node
    this.index = this.size
    return 0
  enddef

  # only delete the node from list
  def Del(node: Node): number
    # update current node first if need
    if this.curr == node
      this.curr = node != this.Last() ? node.next : node.prev
    endif

    node.prev.next = node.next
    node.next.prev = node.prev
    node.prev = node
    node.next = node

    this.size -= 1
    this._Reindex()
    return 0
  enddef
endclass
# }}}

# use list for traverse, dict for index
var sList: List = List.new()
var sDict: dict<Node> = {}

export def Add(obj: TermObj): number
  var node = Node.new(obj)
  if sList.Add(node)
    return -1
  endif

  sDict[obj.bufnr] = node
  return 0
enddef

# also close the terminal if `autoclose` is true
export def Del(obj: TermObj): number
  if sList.Del(sDict[obj.bufnr])
    return -1
  endif
  remove(sDict, obj.bufnr)

  # terminal the terminal process
  if g:ivim_term_autoclose
    # term_sendkeys(obj.bufnr, tr(&termwinkey, "<C", "\<C") .. "\<C-c>")
  endif
  return 0
enddef

export def Has(bufnr: number): bool
  return has_key(sDict, bufnr)
enddef

export def Find(bufnr: number): TermObj
  return sDict[bufnr]
enddef

export def First(): TermObj
  if sList.Empty()
    throw "no termnial"
  endif
  return sList.First().obj
enddef

export def Last(): TermObj
  if sList.Empty()
    throw "no termnial"
  endif
  return sList.Last().obj
enddef

# get all managered buffer
export def GetBufList(): list<number>
  var n: Node = sList.First()
  var res: list<number> = []
  while n != sList.head
    res->add(n.obj.bufnr)
    n = n.next
  endwhile
  return res
enddef

# clear all managered buffer
export def Clear(): void
  while !sList.Empty()
    var obj = sList.First().obj
    Del(obj)
  endwhile
enddef

# {{{ unit test
export def Test(): void
  # clear first
  Clear()

  var o1 = TermObj.new()
  var o2 = TermObj.new()
  var o3 = TermObj.new()

  Add(o1)
  Add(o2)
  Add(o3)

  if First() != o1
    throw "wrong first node"
  endif
  if Last() != o3
    throw "wrong last node"
  endif

  if !Has(o1.bufnr) || !Has(o2.bufnr) || !Has(o3.bufnr)
    throw "miss buffer"
  endif

  Del(o1)
  if len(GetBufList()) != 2
    throw "wrong buffer number"
  endif

  Clear()
enddef
# }}}
