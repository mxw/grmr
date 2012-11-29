#
# list.rb - Circular linked list.
#

class ListEmptyError < StandardError; end

class List
  include Enumerable

  def initialize
    @guard = GuardNode.new self
    @guard.next = @guard
    @guard.prev = @guard
  end

  def each
    current = @guard.next
    while not current.equal? @guard
      yield current
      current = current.next
    end
  end

  def each_value
    each { |node| yield node.value }
  end

  #
  # Shallow copy.
  #
  def copy
    inject(self.class.new) { |list, node| list << node.value }
  end

  def empty?
    @guard.equal? @guard.next
  end

  def head
    raise ListEmptyError if empty?
    @guard.next
  end

  def tail
    raise ListEmptyError if empty?
    @guard.prev
  end

  def <<(value)
    append! value; self
  end

  def append!(value)
    @guard.ins_before value
  end

  def prepend!(value)
    @guard.ins_after value
  end

  def concat!(list)
    @guard.splice_before list
  end

  def to_s
    inject('') { |acc, node| acc + node.to_s + "\n" }
  end

  private

  class Node
    attr_accessor :next, :prev, :value

    def initialize(value)
      @value = value
    end

    def <=>(node)
      @value <=> node.value
    end

    def to_s
      @value.to_s
    end

    def is_guard?; false; end

    #
    # Insert a new node for `value' after self.
    #
    def ins_after(value)
      node = Node.new value

      node.prev = self
      node.next = @next
      @next.prev = node
      @next = node

      return
    end

    #
    # Insert a new node for `value' before self.
    #
    def ins_before(value)
      node = Node.new value

      node.next = self
      node.prev = @prev
      @prev.next = node
      @prev = node

      return
    end

    #
    # Inline the contents of `list' after self; destroys `list'.
    #
    def splice_after(list)
      @next.prev = list.tail
      list.tail.next = @next
      @next = list.head
      list.head.prev = self

      return
    end

    #
    # Inline the contents of `list' before self; destroys `list'.
    #
    def splice_before(list)
      @prev.next = list.head
      list.head.prev = @prev
      @prev = list.tail
      list.tail.next = self

      return
    end

    #
    # Remove a node from the list, returning the removed node.
    #
    def remove
      @prev.next = @next
      @next.prev = @prev
      self
    end
  end

  class GuardNode < Node
    def initialize(list)
      @value = nil
      @list = list
    end

    def is_guard?; true; end
    def list; @list; end
  end
end
