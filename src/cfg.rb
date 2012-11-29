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
      nonterm = rhs.find { |node| node.value[0].chr == '~' }
      break if nonterm.nil?
      nonterm.value = expand nonterm.value
    end

    rhs = rhs.inject('') { |str, node| str + node.to_s }
    @cache[symbol] = rhs
  end

  def subst!(nonterm, string)
    @rules.each do |_, rhs|
      # XXX: ~ check.
      nodes = rhs.select { |node| node.value == nonterm }
      nodes.each { |node| node.value = string }
    end
  end

  def replace!(find_symb, repl_symb)
    # If the RHS of repl_symb contains find_symb, we need inline find_symb's
    # RHS a single level to avoid creating cycles.
    # XXX: ~ check.
    cycle_nodes = @rules[repl_symb].select { |node| node.value == find_symb }
    cycle_nodes.each do |lhs_node|
      @rules[find_symb].each_value { |str| lhs_node.ins_before str }
      lhs_node.remove
    end

    @rules.delete find_symb
    subst! find_symb, repl_symb
    @cache = {}
  end

  def counts
    @rules.inject(Hash.new(0)) do |counts, (lhs, rhs)|
      counts[lhs] = 2 if lhs == @start

      rhs.each do |node|
        counts[node.value] += 1 if node.value[0] == '~'
      end

      counts
    end
  end
end
