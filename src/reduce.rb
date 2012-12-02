#
# reduce.rb - Yang and Kieffer's grammar reduction algorithm
#

require_relative 'cfg.rb'
require_relative 'util.rb'

class Reducer
  attr_reader :cfg

  def initialize(cfg)
    @cfg = cfg
  end

  def run
    while [
      eliminate_singletons,
      unify_internal,
      unify_pairwise,
      apply_rules,
      eliminate_duplicates
    ].any?; end
  end

  private

  #
  # R1: Eliminate any rules which are used only once in the CFG.
  #
  def eliminate_singletons
    @cfg.count.inject(false) do |found, (nonterm, count)|
      next found if count != 1
      @cfg.inline! nonterm
      true
    end
  end

  class Retry < StandardError; end

  #
  # R2: Unify pairs of substrings (of length at least 2) within a single rule
  # by making a new rule for them.
  #
  def unify_internal
    @cfg.rules.each do |(lhs, rhs)|
      seq = rhs.join[/(.*)(.*)\1/, 1]
      next if seq.nil?

      nonterm = @cfg.add_rule(seq)
      @cfg.factor! lhs, nonterm
    end
  end

  #
  # Loop through pairs of stringified rules, yielding the shorter rule first.
  #
  def each_rule_pair
    rules = Hash[@cfg.rules.map { |lhs, rhs| [lhs, rhs.join('')] }]

    rules.each_index { |rule1, i| rules.each_index { |rule2, j|
      next unless j < i
      yield [rule1, rule2].sort_by { |(_, rhs)| rhs.size }
    } }
  end

  #
  # General method for finding substring matches between pairs of RHS
  # expansions and then reducing.
  #
  # @param match    Function which takes two RHS's, returning truthy data on
  #                 match or falsey on no-match.
  # @param reduce   Function which takes two LHS's and reduces @cfg.
  # @return   True if any matches were made, else false.
  #
  def match_reduce(match, reduce)
    found = false

    begin
      each_rule_pair do |(lhs1, rhs1), (lhs2, rhs2)|
        if (res = match(rhs1, rhs2))
          reduce(lhs1, lhs2, res)
          found = true
          raise Retry
        end
      end
    rescue Retry
      retry
    end

    found
  end

  #
  # R3: Unify pairs of substrings (of length at least 2) between two different
  # rules by making a new rule for them.
  #
  def unify_pairwise
    match_reduce(
      ->(rhs1, rhs2) {
        s = lcs(rhs1, rhs2)
        s.size >= 2 && s
      },
      ->(lhs1, lhs2, seq) {
        nonterm = @cfg.add_rule(seq)
        @cfg.factor! lhs1, nonterm
        @cfg.factor! lhs2, nonterm
      }
    )
  end

  #
  # R4: If any sequences correspond to existing rules, substitute the
  # appropriate nonterminal.
  #
  def apply_rules
    match_reduce(
      ->(rhs1, rhs2) { rhs1.size >= 2 and rhs2.include? rhs1 },
      ->(lhs1, lhs2, _) { @cfg.factor! lhs2, lhs1 }
    )
  end

  #
  # R5: Eliminate duplicate rules.
  # XXX: This may create unused rules(?), which should be deleted.
  #
  def eliminate_duplicates
    match_reduce(
      ->(rhs1, rhs2) { rhs1 == rhs2 },
      ->(lhs1, lhs2, _) { @cfg.replace! lhs2, lhs1 }
    )
  end
end
