#
# fidelity.rb - Analysis framework for comparing the fidelity between a string
# and its compressed output.
#

require 'bzip2'
require 'descriptive_statistics'
require 'levenshtein'

require_relative 'util.rb'

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
      s + "%2s " % (k.to_s + ':') + v.to_s + "\n"
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

#
# Perform some statistical analysis on a string.  If a second string is
# supplied as an argument, we compare `s' against it.
#
def fanalyze(s1, s2=nil)
  res =  "Total Length:      %d\n" % [s1.size]
  res += "Distance:          %f\n" %
         [Levenshtein.distance(s1, s2).to_f / s2.size.to_f] if s2 != nil
  res += "Avg Word Length:   %f\n" % [avgwordlen(s1)]
  res += "Entropy:           %d\n" % [entropy(s1)]
  (1..3).inject(res) do |res, i|
    res + "%d-grams:\n%s\n" % [i, ngrams(s1, i).indent(4)]
  end
end
