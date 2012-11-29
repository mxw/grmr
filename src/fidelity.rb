# Complete analysis framework for comparing the fidelity between the compressed final string and the original

require 'rubygems'
require 'bzip2'
require 'descriptive_statistics'
require 'levenshtein'

#returns how large the string is after bzip compression
def entropy(s)
  writer = Bzip2::Writer.new File.new('temp',mode="w")
  writer << s
  writer.close
  return File.size('temp')
end

def avgwordlen (s)
  words = s.split /\s+/
  words.map! {|w| w.length}
  words.extend(DescriptiveStatistics)
  return words.mean
end

#statistics on the ngram distribution
def ngrams (s, n)
  ## maps ngrams to their counts
  nmap = {}
  len = s.length
  curNGram = nil
  for i in 0..(len-n)
    curNGram = s[i,n]
    if nmap.has_key? curNGram
      nmap[curNGram] += 1
    else
      nmap[curNGram] = 1
    end
  end
  counts = []
  nmap.each do |key,val|
    counts << val
  end
  counts.extend(DescriptiveStatistics)
  return {
    "num" => counts.number,
    "mean" => counts.mean,
    "max" => counts.max,
    "stddev" => counts.standard_deviation
  }
end

# assume we have ?_in and ?_out as the two files to compare
def processCase (fprefix)
  f1 = File.new(fprefix+"_in")
  f2 = File.new(fprefix+"_out")
  f3 = File.new(fprefix+"_res",mode="w")
  str1 = f1.read
  str2 = f2.read
  len1 = str1.length
  len2 = str2.length
  maxlen = [len1,len2].max
  f3.puts("Total Length: %d, %d" % [len1, len2])
  f3.puts("Avg Word Lengths: %f, %f" % [avgwordlen(str1),avgwordlen(str2)])
  for i in 1..3
    f3.puts("%d-grams: %s, %s" % [i, ngrams(str1,i).to_s,ngrams(str2,i).to_s])
  end
  distfrac = Float(Levenshtein.distance(str1,str2)) / Float(maxlen)
  f3.puts("Levenshtein: %f" % [distfrac])
  f3.puts("Entropy: %d, %d" % [entropy(str1), entropy(str2)])
  f1.close
  f2.close
  f3.close
end

processCase "test"
