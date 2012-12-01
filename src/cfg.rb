#
# Context-Free Grammar structure.
#

require_relative 'list.rb'

class CFG
  attr_accessor :rules

  def initialize(start='*', rules={})
    @start = start
    @rules = rules
    @cache = {}
  end

  def [](token)
    @rules[token]
  end

  def []=(token, rhs)
    @cache = {}
    @rules[token] = rhs
  end

  def to_s
    @rules.sort.inject('') do |string, (lhs, rhs)|
      string + lhs + ' => ' + rhs.to_a.join('') + "\n"
    end
  end

  def nonterm?(str)
    str[0].chr == '~'
  end
  private :nonterm?

  #
  # Shallow copy.
  #
  def copy
    rules_copy = @rules.inject({}) do |rules_copy, (lhs, rhs)|
      rules_copy[lhs] = rhs.copy
      rules_copy
    end
    CFG.new @start, rules_copy
  end

  #
  # Expand a rule out to a string of nonterminals.
  #
  def expand(symbol='*')
    # Use the cached value if possible.
    return @cache[symbol] if @cache.key? symbol

    rhs = @rules[symbol].copy
    loop do
      nonterm = rhs.find { |node| nonterm? node.value[0] }
      break if nonterm.nil?
      nonterm.value = expand nonterm.value
    end

    rhs = rhs.inject('') { |str, node| str + node.to_s }
    @cache[symbol] = rhs
  end

  #
  # Iterate over all RHS nonterminal symbols.  If a symbol is provided as
  # argument, iterates only over matching nonterminals.
  #
  def each_nonterm(nonterm=nil)
    @rules.each do |_, rhs|
      nodes = rhs.select { |node| nonterm.nil? || node.value == nonterm }
      nodes.each { |node| yield node }
    end
  end

  #
  # Replace all instances of a nonterminal with another nonterminal symbol.
  #
  def replace!(find_symb, repl_symb)
    # If the RHS of repl_symb contains find_symb, we need to inline find_symb's
    # RHS a single level to avoid creating cycles.  Since our CFG is finite,
    # a single level of inlining is guaranteed not to create further cycles.
    cycle_nodes = @rules[repl_symb].select { |node| node.value == find_symb }
    cycle_nodes.each do |lhs_node|
      lhs_node.replace_with_before @rules[find_symb].copy
    end

    @rules.delete find_symb
    subst_symb! find_symb, repl_symb
    @cache = {}
  end

  def replace(find_symb, repl_symb)
    copy.replace! find_symb, repl_symb
  end

  #
  # Inline all instances of a nonterminal with its RHS.
  #
  def inline!(nonterm)
    rhs = @rules[nonterm]
    @rules.delete nonterm
    subst_list! nonterm, rhs.copy
  end

  def inline(nonterm)
    copy.inline! nonterm
  end

  #
  # Count the number of times each nonterminal appears in the RHS of a rule.
  # The start symbol starts off with a count of 2.
  #
  def counts
    @rules.inject(Hash.new(0)) do |counts, (lhs, rhs)|
      counts[lhs] += 2 if lhs == @start
      rhs.each { |node| counts[node.value] += 1 if nonterm? node.value }
      counts
    end
  end

  private

  #
  # Substitute all instances of a nonterminal for a terminal string.
  #
  def subst_symb!(nonterm, string)
    each_nonterm(nonterm) { |node| node.value = string }
  end

  #
  # Substitute all instances of a nonterminal for a sequence of symbols.  The
  # list is spliced destructively.
  #
  def subst_list!(nonterm, list)
    each_nonterm(nonterm) { |node| node.replace_with_before list }
  end
end
