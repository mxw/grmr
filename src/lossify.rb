#
# lossify.rb - CFG lossifier algorithms.
#

require 'levenshtein'

module Lossifier

  #
  # The Similarity algorithm works as follows:
  #   1.  Loop while there exist a pair of RHS's with similarity above the
  #       threshold.
  #   2.  Find the most similar pair of RHS's of rules based on a
  #       parametrizable similarity metric.
  #   3.  Replace the less common of the variables with the more common.
  #
  class Similarity

    def initialize(cfg, verbose=false, threshold=0.5)
      @cfg = cfg.copy
      @verbose = verbose
      @threshold = threshold
    end

    def run
      return @cfg if @cfg.rules.size < 2

      puts "> Elimination:" if @verbose

      1.upto(Float::INFINITY) do |i|
        find, repl = eliminate
        break if find.nil? or repl.nil?
        puts ">   [#{i}]".ljust(10) + find + ':' + repl if @verbose
      end
      puts "\n" if @verbose

      @cfg
    end

    private

    def eliminate
      nonterms = @cfg.rules.keys

      nonterms.each do |nonterm1|
        rhs1 = @cfg.expand nonterm1

        nonterms.each do |nonterm2|
          next if nonterm1 == nonterm2

          rhs2 = @cfg.expand nonterm2
          next if rhs1.size > rhs2.size

          dist = Levenshtein.distance(rhs1, rhs2) / rhs2.size.to_f
          if dist < @threshold
            counts = @cfg.counts

            # Replace the less common variable, or, in the case of a tie,
            # the variable with the longer rule.
            if counts[nonterm1] >= counts[nonterm2]
              @cfg.replace! nonterm2, nonterm1
              ret = [nonterm2, nonterm1]
            else
              @cfg.replace! nonterm1, nonterm2
              ret = [nonterm1, nonterm2]
            end

            return ret
          end
        end
      end

      return []
    end
  end

  #
  # The Cluster algorithm is like the Similarity algorithm; however, instead of
  # iterating over pairs of similar rules, Cluster first partitions the entire
  # rulespace into similarity classes based on some threshold.  These clusters
  # are then unified iteratively.  The caching behavior of CFG#expand yields
  # high potential for savings if we don't call replace for every pair.
  #
  class Cluster

    def initialize(cfg, verbose=false, epsilon=0.4)
      @cfg = cfg.copy
      @verbose = verbose
      @epsilon = epsilon
    end

    def run
      clusters.each do |cluster|
        counts = @cfg.counts
        repl_sym = cluster.max_by { |nonterm| counts[nonterm] }

        cluster.each do |find_sym|
          next if find_sym == repl_sym
          @cfg.replace! find_sym, repl_sym
        end
      end

      @cfg
    end

    private

    def clusters
      nonterms = @cfg.rules.keys

      nonterms.inject([]) do |clusters, nonterm|
        # If we have no clusters, create the first.
        if clusters.empty?
          clusters << [nonterm]
          next clusters
        end

        rhs = @cfg.expand nonterm

        clusters.each_with_index do |cluster, i|
          rep_rhs = @cfg.expand cluster.first

          size = [rhs.size, rep_rhs.size].max
          dist = Levenshtein.distance(rhs, rep_rhs) / size.to_f

          if dist < @epsilon
            cluster << nonterm
            break
          end

          if i == clusters.size - 1
            clusters << [nonterm]
            break
          end
        end

        clusters
      end
    end
  end
end
