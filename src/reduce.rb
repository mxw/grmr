#
# reduce.rb - Yang and Kieffer's grammar reduction algorithm.
#

require_relative 'cfg.rb'
require_relative 'verb.rb'

class Reducer
  attr_reader :cfg

  def initialize(cfg, verbose=false)
    @cfg = cfg
    @verbose = verbose
  end

  def run
    verb_loop('Reduction', @verbose) do
      res = [ eliminate_singletons,
              unify_internal,
              unify_pairwise,
              apply_rules,
              eliminate_duplicates]
      break unless res.any?
      res.map { |e| e ? 1 : 0 }.join(', ')
    end

    @cfg
  end

  private

  class Retry < StandardError; end

  #
  # Convert a string of symbols into a list.
  #
  def listify(str)
    str.split(/(~\[\w*\])/).inject(List.new) do |list, s|
      if @cfg.nonterm s then
        list << s
      else
        # This also handles the s.empty? case.
        s.split('').each { |c| list << c }
      end
      list
    end
  end

  #
  # Compute a longest common substring given two symbol lists.
  #
  def lcs(l1, l2)
    k = z = 0
    m = Array.new(l1.length + 1){ Array.new(l2.length + 1) { 0 } }

    l1.values.each_with_index do |symb1, i|
      l2.values.each_with_index do |symb2, j|
        if symb1 == symb2
          m[i + 1][j + 1] = m[i][j] + 1
          if m[i + 1][j + 1] > z
            z = m[i + 1][j + 1]
            k = i - z + 1
          end
        end
      end
    end

    l1.values.each_with_index.inject(List.new) do |l, (symb, i)|
      if i >= k and i < k + z then l << symb else l end
    end
  end

  #
  # Find the longest disjoint substring pair given a symbol list.
  #
  def ldsp(l)
    left_size = l.size / 2

    left, right =
      l.values.each_with_index.inject([List.new, List.new]) do |(l, r), (v, i)|
        if i < left_size then [l << v, r] else [l, r << v] end
      end

    i = size = 0
    right_s = right.join('')

    catch :done do
      (1..left_size).reverse_each do |len|
        left.each_cons(len).each_with_index do |subseq, k|
          if right_s.include? subseq.join('')
            i, size = k, len
            throw :done
          end
        end
      end
    end

    l.values.each_with_index.inject(List.new) do |list, (symb, k)|
      break list if k >= i + size

      if k >= i and k < i + size
        list << symb
      else
        list
      end
    end
  end

  #
  # Loop through pairs of (lhs,rhs-pair) pairs, yielding the shorter rule first.  
  # We yield the
  # rule as well as a stringified version to avoid unnecessary operations.
  #
  def each_rule_pair
    rules = @cfg.rules.dup
    rules_s = @cfg.rules_s
    sizes = Hash[rules.map { |lhs, rhs| [lhs, rhs.size] }]

    rules.each_with_index do |(lhs1, rhs1), i|
      rules.each_with_index do |(lhs2, rhs2), j|
        next unless j < i

        rule1 = [lhs1, [rhs1, rules_s[lhs1]]]
        rule2 = [lhs2, [rhs2, rules_s[lhs2]]]

        yield [rule1, rule2].sort_by { |lhs, _| sizes[lhs] }
      end
    end
  end

  #
  # General method for finding substring matches between pairs of RHS
  # expansions and then reducing.
  #
  # @param match    Function which takes two RHS-pair's, returning truthy data on
  #                 match or falsey on no-match.
  # @param reduce   Function which takes two LHS's and reduces @cfg.
  # @return   True if any matches were made, else false.
  #
  def match_reduce(match, reduce)
    found = false

    begin
      each_rule_pair do |(lhs1, rhsp1), (lhs2, rhsp2)|
        if (res = match.call(rhsp1, rhsp2))
          reduce.call(lhs1, lhs2, res)
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
  # R1: Eliminate any rules which are used only once in the CFG.
  #
  def eliminate_singletons
    @cfg.counts.inject(false) do |found, (nonterm, count)|
      next found if count != 1
      @cfg.inline! nonterm
      true
    end
  end

  #
  # R2: Unify pairs of substrings (of length at least 2) within a single rule
  # by making a new rule for them.
  #
  def unify_internal
    @cfg.rules.dup.inject(false) do |found, (lhs, rhs)|
      seq = ldsp(rhs)
      next found if seq.size < 2

      nonterm = @cfg.add_rule(seq)
      @cfg.factor! lhs, nonterm
      true
    end
  end

  #
  # R3: Unify pairs of substrings (of length at least 2) between two different
  # rules by making a new rule for them.
  #
  def unify_pairwise
    match_reduce(
      ->((rhs1, _), (rhs2, _)) {
        seq = lcs(rhs1, rhs2)
        seq.size >= 2 && rhs1.size > 2 && rhs2.size > 2 && seq
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
      ->((rhs1, rhs1_s), (_, rhs2_s)) {
        rhs1.size >= 2 and rhs2_s.include? rhs1_s
      },
      ->(lhs1, lhs2, _) { @cfg.factor! lhs2, lhs1 }
    )
  end

  #
  # R5: Eliminate duplicate rules.
  # XXX: This may create unused rules(?), which should be deleted.
  #
  def eliminate_duplicates
    match_reduce(
      ->((_, rhs1_s), (_, rhs2_s)) { rhs1_s == rhs2_s },
      ->(lhs1, lhs2, _) { @cfg.replace! lhs2, lhs1 }
    )
  end
end
