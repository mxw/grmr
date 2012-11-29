#
# lossify.rb - CFG lossifier algorithms.
#

require 'rubygems'
require 'levenshtein'

require_relative 'list.rb'
require_relative 'cfg.rb'
require_relative 'sequitur.rb'

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

    def initialize(cfg, threshold=0.5)
      @cfg = cfg
      @threshold = threshold
    end

    def run
      while eliminate do; end
      return @cfg
    end

    private

    def eliminate
      nonterms = @cfg.rules.keys
      return @cfg if nonterms.size < 2

      nonterms.each do |nonterm1|
        rhs1 = @cfg.expand nonterm1

        nonterms.each do |nonterm2|
          next if nonterm1 == nonterm2

          rhs2 = @cfg.expand nonterm2
          next if rhs1.size > rhs2.size

          dist = (Levenshtein.distance rhs1, rhs2) / rhs2.size.to_f
          if dist < @threshold
            counts = @cfg.counts

            # Replace the less common variable, or, in the case of a tie,
            # the variable with the longer rule.
            if counts[nonterm1] >= counts[nonterm2]
              @cfg.replace! nonterm2, nonterm1
            else
              @cfg.replace! nonterm1, nonterm2
            end

            return true
          end
        end
      end

      return false
    end
  end
end

#str = "aactgaacatgagagacatagagacag"
#str = "testtesttesttesk"
#str = "test1test2test3tesg4"
#str = "a[a[a[a[xx]a[xx]]a[a[xx]a[xx]]]a[a[a[xx]a[xx]]a[a[xx]a[xx]]]]"
#str = File.read('lorem2.txt')
str = File.read('jabber.txt')

#puts "Usage: ./lossify input-text" if ARGV[0].nil?

cfg = Sequitur.new(str).run
puts cfg.expand

cfg = Lossifier::Similarity.new(cfg).run
puts cfg.expand
