require "sequitur"

class Grammar
  attr_accessor :rules, :start
  def initialize()
    @start = nil
    @rules = []
  end
  def addRule(newRule)
    @rules = @rules << newRule
  end
  def to_s
    out = "Start: "+@start.to_s+"\n"
    for curRule in @rules
      out += (curRule.to_s)+"\n"
    end
    return out
  end
end

class GRule
  attr_accessor :left, :right
  def initialize(left,right=[])
    @left = left
    @right = right
  end
  def to_s
    return (@left.to_s + " :> " + @right.to_s)
  end
end

class GSymbol
  attr_accessor :token, :isVar
  def initialize(isVar,token)
    @isVar = isVar
    @token = token
  end
  def to_s
    return @token
  end
end

def convert_seq(seqGrammar)
  newGramm = Grammar.new()

  curRules = [seqGrammar]
  nonterminals = {"*" => true}
  newGramm.start = GSymbol.new(true,"*")
  curRules.each do |rule|
    newVar = GSymbol.new(true,rule.token)
    newSeq = []
    nextsym = rule.next
    until nextsym.is_head? do
      if not nextsym.rule.nil?
        curRules << nextsym.rule if not nonterminals[nextsym.token]
        nonterminals[nextsym.token] = true
        newSeq << GSymbol.new(true,nextsym.token)
      else
        newSeq << GSymbol.new(false,nextsym.token)
      end
      nextsym = nextsym.next
    end
    newGramm.addRule(GRule.new(newVar,newSeq))
  end
  return newGramm
end

str = "aactgaacatgagagacatagagacag"
gramm1 = Sequitur.new(str).run
myGrammar = convert_seq(gramm1)
puts myGrammar.to_s
