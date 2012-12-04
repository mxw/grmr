#
# graphplot.rb - Visualization for grammars.
#

require 'graphviz'

require_relative 'cfg.rb'

def plot_cfg(cfg, fname)
  GraphViz.new(:G, :type => :digraph, :ordering => :out) do |g|
    cfg.rules.each { |lhs, _| g.add_nodes(lhs) }

    cfg.rules.each do |lhs, rhs|
      lhs_node = g.get_node(lhs)

      rhs.values.select { |sym|
        cfg.nonterm? sym
      }.inject(Hash.new(0)) { |counts, sym|
        counts[sym] += 1
        counts
      }.each { |sym, count|
        puts count.to_s
        g.add_edges(lhs_node, g.get_node(sym), :label => count.to_s)
      }
    end
  end.output(:png => fname + '.png')
end
