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
@options = OpenStruct.new
@options.algorithms = ALGORITHMS.values
@options.analysis = false
@options.expand = false
@options.print = false
@options.plot = false
@options.reduce = false
@options.verbose = false
@options.thresh = 0.4

OptionParser.new do |opts|
  opts.banner = USAGE

  opts.on("-a", "--[no-]analysis", "Perform final analysis") do |a|
    @options.analysis = a
  end

  opts.on("-e", "--[no-]expand", "Print expansion") do |e|
    @options.expand = e
  end

  opts.on("-g", "--[no-]print-grammar", "Print grammar") do |g|
    @options.print = g
  end

  opts.on("-p", "--[no-]plot-grammar", "Plot grammar") do |p|
    @options.plot = p
  end

  opts.on("-r", "--[no-]reduce", "Apply grammar reductions") do |r|
    @options.reduce = r
  end

  opts.on("-t", "--threshold N", Float, "Similarity threshold level") do |t|
    @options.thresh = t
  end

  opts.on("-l", "--lossifiers algo1,algo2,algon", Array,
          "The lossifier algorithms to use") do |algos|
    if algos == [ 'none' ]
      @options.algorithms = []
      next
    end

    raise OptionParser::InvalidArgument unless (algos - ALGORITHMS.keys).empty?
    @options.algorithms = algos.uniq.map { |algo| ALGORITHMS[algo] }
  end

  opts.on("-v", "--verbose", "Run verbosely") do |v|
    @options.verbose = v
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

def output_cfg(title, time, cfg)
  time = '[' + time.to_s + 's]'
  puts title + '-' * (79 - (title.size + time.size)) + time + "\n\n"

  puts cfg if @options.print
  puts "\n"

  if @options.analysis
    puts ("Rules:             %d" % [cfg.rules.size])
    puts ("Size:              %d" % [cfg.size])
    puts "\n"
  end

  puts cfg.expand if @options.expand
  puts "\n"

  plot_cfg cfg, @fprefix + '-' + title if @options.plot
end

def time
  t1 = Time.now
  res = yield
  t2 = Time.now
  [res, t2 - t1]
end

str = File.read(ARGV[0])
@fprefix = ARGV[0].rpartition('.').first

icfg, t = time { Sequitur.new(str).run }
output_cfg 'Sequitur', t, icfg
fanalyze str if @options.analysis

@options.algorithms.each do |algo|
  lcfg, t = time { algo.new(icfg, @options.verbose, @options.thresh).run }
  output_cfg algo.name, t, lcfg

  if @options.reduce
    rlcfg, t = time { Reducer.new(lcfg, @options.verbose).run }
    output_cfg algo.name + "-Reduced", t, rlcfg
  end

  fanalyze lcfg.expand, str if @options.analysis
end
