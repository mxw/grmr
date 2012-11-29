#!/usr/bin/ruby

#
# Circular linked list entry for a CFG symbol.
#

class SymbolNode
  # @rule.nil? if the SymbolNode is terminal
  attr_accessor :token, :rule
  attr_accessor :refcount, :next, :prev

  def initialize(token, rule=nil, is_head=false)
    @token = token
    @rule = rule
    @rule.refcount += 1 unless @rule.nil?

    @refcount = 0
    @next = self
    @prev = self
    @is_head = is_head
  end

  def is_head?
    @is_head
  end

  #
  # Add `symbol' to the list after ourselves.
  #
  def ins_after(symbol)
    symbol.prev = self
    symbol.next = @next
    @next.prev = symbol
    @next = symbol  # return symbol
  end

  #
  # Add `symbol' to the list before ourselves.
  #
  def ins_before(symbol)
    symbol.next = self
    symbol.prev = @prev
    @prev.next = symbol
    @prev = symbol  # return symbol
  end

  #
  # Append `symbol' to a list, asserting that self is a list head.
  #
  def append(symbol)
    raise TypeError unless self.is_head?
    self.ins_before(symbol)
    self
  end

  #
  # Prepend `symbol' to a list, asserting that self is a list head.
  #
  def prepend(symbol)
    raise TypeError unless self.is_head?
    self.ins_after(symbol)
    self
  end

  #
  # Splice another list into our list, after self's position.
  #
  def splice(head)
    raise TypeError unless head.is_head?
    self.next.prev = head.prev
    head.prev.next = self.next
    self.next = head.next
    head.next.prev = self  # return self
  end

  #
  # Remove a symbol from the list.
  #
  def remove
    @prev.next = @next
    @next.prev = @prev
    self
  end

  #
  # Delete a symbol, suggesting that it will not be reused and decrementing the
  # refcount on any attached rule.
  #
  def delete
    @rule.refcount -= 1 unless @rule.nil?
    self.remove
  end

  #
  # Stringifies a digram, throwing an error if we exceeded the bounds of the
  # symbol list.
  #
  def digram
    raise RangeError if self.is_head? or self.next.is_head?
    self.token + '#' + self.next.token
  end
end

#
# Sequitur instance.
#
class Sequitur
  def initialize(input)
    @input = input
    @index = {}
    @grammar = SymbolNode.new("*", nil, true)
    @nonterm = '@'
  end

  def run
    @grammar.append(SymbolNode.new(@input[0].chr))

    @input[1..-1].each_char do |c|
      symbol = SymbolNode.new(c)
      @grammar.append(symbol)
      process symbol.prev
    end
    @grammar
  end

  def gen_nonterm
    @nonterm = @nonterm.succ
  end

  #
  # Removes a digram from the index.
  #
  def unindex(symbol)
    @index.delete symbol.digram rescue nil
  end

  #
  # Break the neighbor digrams of a given digram.
  #
  def isolate(symbol)
    unindex symbol.prev
    unindex symbol.next
  end

  def _replace(symbol, rule, &rm)
    # Break the neighbor digrams.
    isolate symbol

    # Replace the digram with a nonterminal.
    nonterm = symbol.ins_before SymbolNode.new(rule.token, rule)
    rm.call(symbol, rule)

    # Process the new neighbor digrams.
    process nonterm.prev
    process nonterm
  end
  private :_replace

  #
  # Replace a digram with a nonterminal for the given rule.
  #
  def replace(symbol, rule)
    _replace(symbol, rule) do |symbol, rule|
      symbol.next.delete
      symbol.delete
    end
  end

  #
  # Replace a digram with a nonterminal for the given rule, but use the digram
  # to populate the rule.
  #
  def rule_swap(symbol, rule)
    _replace(symbol, rule) do |symbol, rule|
      rule.ins_after symbol.next.remove
      rule.ins_after symbol.remove
    end
  end

  def inline(nonterm)
    return if nonterm.rule.nil? or nonterm.rule.refcount > 1

    # Splice in the rule to replace the nonterminal.
    left, right = nonterm.prev, nonterm.next
    nonterm.splice nonterm.rule
    nonterm.delete

    # Process the new neighbor digrams.
    process left
    process right.prev
  end

  def process(symbol)
    # Stringify the digram.
    dg = symbol.digram rescue return

    if ARGV[0] == "-v"
      puts_grammar @grammar
    end

    if @index.key? dg
      # The digram is repeated.  First, see if the instances overlap, and if so,
      # do nothing.
      return if @index[dg] == symbol or
                @index[dg] == symbol.next or
                @index[dg].next == symbol

      # Check if the other occurence is a complete rule.
      if @index[dg].prev == @index[dg].next.next
        rule = @index[dg].prev
      else
        # Make a new rule.
        rule = SymbolNode.new(gen_nonterm, nil, true)

        # Replace the indexed digram with a nonterminal, and populate the new
        # rule with the removed digram.  This ensures that the rule's digram is
        # the one we index, as desired.
        rule_swap(@index[dg], rule)
      end

      # Replace the new digram with a nonterminal.
      replace(symbol, rule)

      # Inline (i.e., delete) rules at the other digram if necessary.
      if not @index[dg].nil?
        inline @index[dg]
        inline @index[dg].next
      end
    else
      # The digram is new, so let's hash it.
      @index[dg] = symbol
    end
  end
end

def puts_grammar(grammar)
  rules = [ grammar ]
  nonterminals = { "*" => true }

  rules.each do |rule|
    output = rule.token + " => "

    symbol = rule.next
    until symbol.is_head? do
      if not symbol.rule.nil?
        rules << symbol.rule if not nonterminals[symbol.token]
        nonterminals[symbol.token] = true
      end

      if symbol.rule == nil
        output += symbol.token
      else
        output += "~"+symbol.token
      end
      symbol = symbol.next
    end
    puts output
  end

  puts "\n"
end

=begin
str = "aactgaacatgagagacatagagacag"

puts "Sequitur : [#{str}]\n\n"
gramm1 = Sequitur.new(str).run
puts_grammar gramm1

puts "Sequitur : [#{str.reverse}]\n\n"
gramm2 = Sequitur.new(str.reverse).run
puts_grammar gramm2

=end
