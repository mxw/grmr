#
# Context-Free Grammar structure.
#

require_relative 'list.rb'

class CFG
  include Enumerable

  attr_reader :rules

  def initialize(nonterm, start='~[*]', rules={})
    @nonterm = nonterm
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
    str[0..1] == '~[' && str[-1].chr == ']'
  end

  #
  # Deep copy.
  #
  def copy
    rules_copy = @rules.inject({}) do |rules_copy, (lhs, rhs)|
      rules_copy[lhs] = rhs.copy
      rules_copy
    end
    CFG.new @nonterm, @start, rules_copy
  end

  #
  # Returns @rules with RHS's stringified.
  #
  def rules_s
    Hash[rules.map { |lhs, rhs| [lhs, rhs.join('')] }]
  end

  #
  # Add a new rule.
  #
  def add_rule(rhs)
    nonterm = '~[' + @nonterm.succ! + ']'
    @rules[nonterm] = rhs
    nonterm
  end

  #
  # Iterate over all RHS nonterminal nodes.  If a symbol is provided as
  # argument, iterates only over matching nonterminals.
  #
  def each_nonterm(nonterm=nil)
    @rules.each do |_, rhs|
      nodes = rhs.select { |node| nonterm.nil? || node.value == nonterm }
      nodes.each { |node| yield node }
    end
  end

  #
  # Expand a rule out to a string of nonterminals.
  #
  def expand(symbol=@start)
    # Use the cached value if possible.
    return @cache[symbol] if @cache.key? symbol

    rhs = @rules[symbol].copy
    loop do
      nonterm = rhs.find { |node| nonterm? node.value }
      break if nonterm.nil?
      nonterm.value = expand nonterm.value
    end

    @cache[symbol] = rhs.join('')
  end

  #
  # Expand all rules, returning a hash of expansions.
  #
  def expand_all
    expand
    @cache
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
    @cache.delete nonterm
    subst_list! nonterm, rhs
  end

  def inline(nonterm)
    copy.inline! nonterm
  end

  #
  # Factor out symbol-for-symbol occurrences of the RHS of nonterm from the
  # target rule.
  #
  def factor!(target, nonterm)
    rhs = @rules[target]
    seq = @rules[nonterm]
    seq_a = seq.to_a
  # counter to make sure not to replace overlapping occurrences
    offsetwait = 0
  # pad the RHS to allow each_cons to get to last symbol
    new_rhs = List.new
    rhs_pad = rhs.copy
    for x in (2..seq_a.size)
      rhs_pad << " "
    end

  # for each candidate sequence in rhs, check to see if we replace
    rhs_pad.each_cons(seq_a.size) do |rhsseq|
      if offsetwait == 0 then
        if rhsseq == seq_a then
          new_rhs << nonterm
          offsetwait = seq_a.size-1
        else
          new_rhs << rhsseq[0].value
        end
      else
        offsetwait -= 1
      end
    end
    # Replace the rule with our refactored rule.
    @rules[target] = new_rhs
  end

  def factor(target, nonterm)
    copy.factor! target, nonterm
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
  # Substitute all instances of a nonterminal for a sequence of symbols.
  #
  def subst_list!(nonterm, list)
    each_nonterm(nonterm) { |node| node.replace_with_before list.copy }
  end
end
