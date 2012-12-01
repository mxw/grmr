require 'rubygems'
require 'graphviz'

require_relative 'cfg.rb'

def plotCFG(gr)
# Create a new graph
  g = GraphViz.new( :G, :type => :digraph, :ordering => :out )
  nodes = {}
  gr.rules.each do |curKey,_|
    nodes[curKey] = g.add_nodes(curKey)
  end
  gr.rules.each do |curKey,curRHS|
    gn1 = nodes[curKey]
    curRHS.each_value do |sym|
      if gr.nonterm? sym then
        g.add_edges(gn1,nodes[sym])
      end
    end
  end
  return g
end

def outputCFG(gr,fname)
  g = plotCFG(gr)
  g.output(:png => fname)
end
