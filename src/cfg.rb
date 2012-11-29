#
# Context-Free Grammar structure.
#

require_relative 'list.rb'

class CFG
  attr_accessor :rules

  def initialize(start='*')
    @start = start
    @rules = {}
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
  # Expand a rule out to a string of nonterminals.
  #
  def expand(symbol='*')
    # Use the cached value if possible.
    return @cache[symbol] if @cache.key? symbol

    rhs = @rules[symbol].inject(List.new) { |list, node| list << node.value }

    loop do
      nonterm = rhs.find { |node| node.value[0].chr == '~' }
      break if nonterm.nil?
      nonterm.value = expand nonterm.value
    end

    rhs = rhs.inject('') { |str, node| str + node.to_s }
    @cache[symbol] = rhs
  end

  def subst!(nonterm, string)
    @rules.each do |lhs, rhs|
      # XXX: ~ check.
      nodes = rhs.select { |node| node.value == nonterm }
      nodes.each { |node| node.value = string }
    end
  end

=begin
  # NOTE: No longer works; subst! no longer takes lists.
  def inline!(nonterm)
    rhs = @rules[nonterm]
    @rules.delete nonterm
    subst! nonterm, rhs
  end
=end

  def replace!(src_symb, dst_symb)
    # If the RHS of dst_symb contains src_symb, we need inline src_symb's RHS a
    # single level to avoid creating cycles.
    # XXX: ~ check.
    src_nodes = @rules[dst_symb].select { |node| node.value == src_symb }
    src_nodes.each do |lhs_node|
      @rules[src_symb].each_value { |str| lhs_node.ins_before str }
      lhs_node.remove
    end

    @rules.delete src_symb
    subst! src_symb, dst_symb
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
