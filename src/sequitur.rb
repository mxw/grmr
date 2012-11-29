#
# sequitur.rb - Sequitur grammar generation.
#

require_relative 'list.rb'
require_relative 'cfg.rb'

class Sequitur
  def initialize(input)
    @input = input
    @index = {}
    @grammar = Rule.new('*')
  end

  def gen_nonterm
    @nonterm = @nonterm.succ
    '~' + @nonterm
  end

  def run
    @nonterm = '@'
    @grammar << (Symb.new @input[0].chr)

    @input[1..-1].each_char do |c|
      @grammar << (Symb.new c)
      process @grammar.tail.prev
    end

    to_cfg @grammar
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
    symbol.ins_before(Symb.new rule.token, rule)
    nonterm = symbol.prev
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
      rule.prepend! symbol.next.remove.value
      rule.prepend! symbol.remove.value
    end
  end

  #
  # Inline a rule in place of a nonterminal, decrementing the rule's refcount
  # and processing the new digrams.
  #
  def inline(nonterm)
    return if nonterm.value.rule.nil? or
              nonterm.value.rule.refcount > 1

    # Splice in the rule to replace the nonterminal.
    left, right = nonterm.prev, nonterm.next
    nonterm.splice_after nonterm.value.rule
    nonterm.delete

    # Process the new neighbor digrams.
    process left
    process right.prev
  end

  #
  # Main Sequitur loop.
  #
  def process(symbol)
    # Stringify the digram.
    dg = symbol.digram rescue return

    if ARGV[0] == "-v"
      puts @grammar
    end

    if @index.key? dg
      # The digram is repeated.  First, see if the instances overlap, and if so,
      # do nothing.
      return if @index[dg] == symbol or
                @index[dg] == symbol.next or
                @index[dg].next == symbol

      # Check if the other occurrence is a complete rule.
      if @index[dg].prev == @index[dg].next.next
        rule = @index[dg].prev.list
      else
        # Make a new rule.
        rule = Rule.new(gen_nonterm)

        # Replace the indexed digram with a nonterminal, and populate the new
        # rule with the removed digram.  This ensures that the rule's digram is
        # the one we index, as desired.
        rule_swap(@index[dg], rule)
        @index[dg] = rule.head
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

  #
  # Convert a Sequitur grammar to a cleaner representation.
  #
  def to_cfg(rule)
    rules = [rule]
    nonterminals = { rule.token => true }

    rules.inject(CFG.new) do |cfg, rule|
      cfg[rule.token] = rule.inject(List.new) do |list, node|
        symbol = node.value

        if not symbol.rule.nil? and not nonterminals[symbol.token]
          rules << symbol.rule
          nonterminals[symbol.token] = true
        end

        list << symbol.token
      end
      cfg
    end
  end

  #
  # List of symbols representing a rule.
  #
  class Rule < List
    attr_accessor :token, :refcount

    def initialize(token)
      @token = token
      @refcount = 0
      super()
    end

    def to_s
      string = inject(@token + ' => ') { |str, node| str + node.to_s }
    end

    Node.class_eval do
      #
      # Delete a symbol, suggesting that it will not be reused and decrementing the
      # refcount on any attached rule.
      #
      def delete
        @value.rule.refcount -= 1 unless @value.rule.nil?
        remove
      end

      #
      # Stringifies a digram, throwing an error if we exceeded the bounds of the
      # symbol list.
      #
      def digram
        raise RangeError if is_guard? or @next.is_guard?
        @value.token + '#' + @next.value.token
      end
    end
  end

  #
  # Symbol type.  Nonterminals point to their corresponding rule.
  #
  class Symb
    attr_reader :token, :rule

    def initialize(token, rule=nil)
      @token = token
      @rule = rule
      @rule.refcount += 1 unless @rule.nil?
    end

    def to_s
      @token.to_s
    end
  end
end
