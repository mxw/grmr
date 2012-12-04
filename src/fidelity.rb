#!/usr/local/bin/ruby

#
# fidelity.rb - Analysis framework for comparing the fidelity between a string
# and its compressed output.
#

require 'rubygems'
require 'bzip2'
require 'descriptive_statistics'
require 'levenshtein'

module Enumerable
  def stats
    { number: number,
      min: min,
      max: max,
      median: median,
      mean: mean,
      stddev: standard_deviation,
    }
  end

  def stats_s
    stats.inject('') do |s, (k, v)|
      s + "%2s " % (k.to_s + ':') + v.to_s + "; "
    end.chop
  end
end

def entropy(s)
  Bzip2.compress(s).size
end

def avgwordlen(s)
  s.split.map { |w| w.size }.mean
end

def ngrams(s, n)
  nmap = Hash.new(0)
  s.chars.each_cons(n) { |ngram| nmap[ngram.join] += 1 }
  nmap.values.stats_s
end

# Print outputs that depend on the final string
# s is processed string, s2 is optional original string
def fanalyze(s,s2=nil)
  puts "Final String Statistics"
  puts ("Total Length:      %d" % [s.size])
  puts ("Distance:          %f" % 
          [Levenshtein.distance(s,s2).to_f/s2.size.to_f]) if s2!=nil
  puts ("Avg Word Length:   %f" % [avgwordlen(s)])
  puts ("Entropy:           %d" % [entropy(s)])
  (1..3).map do |i|
    puts ("%d-grams:\n%s" % [i, ngrams(s, i)])
  end
end
