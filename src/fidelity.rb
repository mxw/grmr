#!/usr/local/bin/ruby

#
# fidelity.rb - Analysis framework for comparing the fidelity between a string
# and its compressed output.
#

require 'rubygems'
require 'bzip2'
require 'descriptive_statistics'
require 'levenshtein'

USAGE = "Usage: ./fidelity.rb file1 file2"

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
      s + "%7s " % (k.to_s + ':') + v.to_s + "\n"
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

def analyze(fn0, fn1, fnout)
  File.open(fn0) { |f0| File.open(fn1) { |f1| File.open(fnout, 'w+') { |fout|
    ss = [f0.read, f1.read]
    sizes = ss.map { |s| s.size }

    [ "Total Length:      %d, %d" % sizes,
      "Avg Word Length:   %f, %f" % ss.map { |s| avgwordlen s },
      "Entropy:           %d, %d" % ss.map { |s| entropy s },
      "Levenshtein:       %f" % [Levenshtein.distance(*ss) / sizes.max.to_f],
      *(1..3).map do |i|
        "%d-grams:\n%s\n%s" % [i, ngrams(ss[0], i), ngrams(ss[1], i)]
      end
    ].each { |s| fout.puts s }
  } } }
end

if ARGV[0].nil? or ARGV[1].nil?
  puts USAGE
  exit
end
outfile = ARGV[2] || 'fid.out'

analyze ARGV[0], ARGV[1], outfile
