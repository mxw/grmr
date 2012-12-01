#
# reduce.rb - Yang and Kieffer's grammar reduction algorithm
#

require_relative 'cfg.rb'

class Reducer
  attr_reader :cfg

  def initialize(cfg)
    @cfg = cfg
  end

  def run
  end

  private

  def stringify(list)
    list.inject('') { |s, node| s + node.value }
  end

  #
  # Eliminate any rules which are used only once in the CFG.
  #
  def eliminate_singletons
    @cfg.count.inject(false) do |found, (nonterm, count)|
      next (found || false) if count != 1
      @cfg.inline! nonterm
      found || true
    end
  end

  #
  # Unify pairs of substrings (of length at least 2) within a single rule by
  # making a new rule for them.
  #
  def unify_internal
    @cfg.rules.each do |(lhs, rhs)|
    end
  end

  #
  # Unify pairs of substrings (of length at least 2) between two different
  # rules by making a new rule for them.
  #
  def unify_pairwise
  end

  #
  # If any sequences correspond to existing rules, substitute the appropriate
  # nonterminal.
  #
  def apply_rules
  end

  #
  # Eliminate duplicate rules.
  # XXX: Paper has some subtleties.
  #
  def eliminate_duplicates
  end
end
