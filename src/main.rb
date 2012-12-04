#!/usr/local/bin/ruby

#
# main.rb - Main executable for running experiments.
#

require 'optparse'
require 'ostruct'

require_relative 'cfg.rb'
require_relative 'list.rb'
require_relative 'lossify.rb'
require_relative 'reduce.rb'
require_relative 'sequitur.rb'
require_relative 'graphplot.rb'
require_relative 'fidelity.rb'

USAGE = "Usage: ./main.rb [options] input-file"
ALGORITHMS = {
  'similarity' => Lossifier::Similarity,
  'cluster' => Lossifier::Cluster,
}

# Default option values.
options = OpenStruct.new
options.algorithms = ALGORITHMS.values
options.expand = false
options.print = false
options.plot = false
options.reduce = false
options.verbose = false
options.analysis = false

OptionParser.new do |opts|
  opts.banner = USAGE

  opts.on("-a", "--[no-]analysis", "Perform final analysis") do |a|
    options.analysis = a
  end

  opts.on("-e", "--[no-]expand", "Print expansion") do |e|
    options.expand = e
  end

  opts.on("-g", "--[no-]print-grammar", "Print grammar") do |g|
    options.print = g
  end

  opts.on("-p", "--[no-]plot-grammar", "Plot grammar") do |p|
    options.plot = p
  end

  opts.on("-l", "--lossifiers algo1,algo2,algon", Array,
          "The lossifier algorithms to use") do |algos|
    if algos == [ 'none' ]
      options.algorithms = []
      next
    end

    raise OptionParser::InvalidArgument unless (algos - ALGORITHMS.keys).empty?
    options.algorithms = algos.uniq.map { |algo| ALGORITHMS[algo] }
  end

  opts.on("-r", "--[no-]reduce", "Apply grammar reductions") do |r|
    options.reduce = r
  end

  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options.verbose = v
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

if ARGV[0].nil?
  puts USAGE
  exit
end

def output_cfg(cfg, options, plotname)
  puts cfg if options.print
  puts cfg.expand if options.expand
  puts "Rules: %d" % [cfg.rules.size] if options.analysis
  puts "Size: %d" % [cfg.size] if options.analysis
  plot_cfg cfg, plotname if options.plot
  puts "\n"
end

def reduce_cfg(cfg, options, plotname)
  cfg = Reducer.new(cfg, options.verbose).run
  output_cfg cfg, options, plotname + '-red'
  cfg
end

#process_cfg prints out data on the CFG structure
def process_cfg(title, options, fprefix, time, cfg)
  puts title + '-' * (79 - title.size) + "\n\n"
  puts "Time: %f" % [time]
  output_cfg cfg, options, fprefix + '-' + title
end

str = File.read(ARGV[0])
fprefix = ARGV[0].rpartition('.').first

#output format:
#Sequitur Grammar Properties
#Original String Properties
#Foreach Algorithm:
#  Grammar Properties
#  (Reduced Grammar Properties)
#  Final String Properties

t1 = Time.now
icfg = Sequitur.new(str).run
t2 = Time.now
process_cfg('Sequitur', options, fprefix, t2-t1, icfg)
fanalyze(str) if options.analysis

options.algorithms.each do |algo|
  t1 = Time.now
  lcfg = algo.new(icfg, options.verbose).run
  t2 = Time.now
  process_cfg(algo.name, options, fprefix, t2-t1, lcfg)
  if options.reduce
    t1 = Time.now
    rlcfg = Reducer.new(lcfg, options.verbose).run
    t2 = Time.now
    process_cfg(algo.name+"-Reduced", options, fprefix, t2-t1, rlcfg)
  end
  fanalyze(lcfg.expand,str) if options.analysis
end
