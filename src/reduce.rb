require "cfg"
require 'rubygems'
require 'levenshtein'

# Lossifier algorithm works as follows:
# > Repeat while there exist similar RHS's above thresh:
#   > Find most similar pair of RHS's of rules based off lcs length / longer RHS
#   > Replace the longer of the rules with the shorter

class Lossifier
  attr_accessor :gramm, :thresh
  def initialize(gramm, thresh=0.5)
    @gramm = gramm
    @thresh = thresh
  end

  # try and combine one pair of rules, return true if successful, false if
  # failed
  def approxOne
    keyset = @gramm.rules.keys
    if keyset.size < 2 then raise "can't reduce" end

    # replace bestold with bestnew
    bestold=""
    bestnew=""
    for key1 in keyset
      rhs1 = @gramm.expandVar(key1).to_s
      for key2 in keyset
        if (key1==key2) then next end
        #rhs1 : GSymbol array
        rhs2 = @gramm.expandVar(key2).to_s
        if (rhs1.size > rhs2.size) then next end
        ## rhs1 <= rhs2 now, no need to double count
        ## lcsLen = lcs(rhs1,rhs2).size
        lDis = Levenshtein.distance(rhs1,rhs2);
        curDifference = Float(lDis)/Float(rhs2.size)
        if curDifference < @thresh
          varcount = @gramm.countVars()
          # replace with the more common variable, or in the case of ties
          # replace with the shorter variable
          if(varcount[key1]>=varcount[key2]) then
            bestold = key2
            bestnew = key1
          else
            bestold = key1
            bestnew = key2
          end
          @gramm.replaceVar(bestold,bestnew)
          return true
        end
      end
    end
    return false
  end

  # iterate reduceOne while it is successful
  def approxAll
    count = 0
    while (approxOne())
      puts "progress"+count.to_s
      count += 1
    end
  end
end

# takes two arrays and returns longest common subsequence
# adapted from rosettacode
def lcs(a, b)
    lengths = Array.new(a.size+1) { Array.new(b.size+1) { 0 } }
    # row 0 and column 0 are initialized to 0 already
    a.each_with_index { |x, i|
        b.each_with_index { |y, j|
            if x == y
                lengths[i+1][j+1] = lengths[i][j] + 1
            else
                lengths[i+1][j+1] = \
                    [lengths[i+1][j], lengths[i][j+1]].max
            end
        }
    }
    # read the substring out from the matrix
    result = []
    x, y = a.size, b.size
    while x != 0 and y != 0
        if lengths[x][y] == lengths[x-1][y]
            x -= 1
        elsif lengths[x][y] == lengths[x][y-1]
            y -= 1
        else
            # assert a[x-1] == b[y-1]
            result << a[x-1]
            x -= 1
            y -= 1
        end
    end
    result.reverse
end

#str = "aactgaacatgagagacatagagacag"
#str = "testtesttesttesk"
#str = "test1test2test3tesg4"
#str = "a[a[a[a[xx]a[xx]]a[a[xx]a[xx]]]a[a[a[xx]a[xx]]a[a[xx]a[xx]]]]"
#str = File.read('lorem2.txt')
str = File.read('jabber.txt')
gramm1 = Sequitur.new(str).run
myGrammar = convert_seq(gramm1)
puts "\n\nReducer test:"
puts myGrammar.to_s
puts "---"
myReducer = Lossifier.new(myGrammar)
myReducer.approxAll
=begin
myReducer.gramm.rules["H"]=createSymList("DEa")
puts (myReducer.gramm.to_s)
=end
myReducer.gramm.reduceGramm()
puts (myReducer.gramm.to_s)
puts (myReducer.gramm.expandAns.to_s)
puts "---custom grammar tests---"
myGrammar = Grammar.new
