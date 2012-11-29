#!/usr/local/bin/ruby

#
# main.rb - Main executable for running experiments.
#

require 'optparse'
require 'ostruct'

require_relative 'cfg.rb'
require_relative 'list.rb'
require_relative 'lossify.rb'
require_relative 'sequitur.rb'

USAGE = "Usage: ./main.rb [options] input-file"
ALGORITHMS = {
  'similarity' => Lossifier::Similarity,
}

# Default option values.
options = OpenStruct.new
options.algorithms = ALGORITHMS.values
options.expand = true
options.print_grammar = false
options.verbose = false

OptionParser.new do |opts|
  opts.banner = USAGE

  opts.on("-e", "--[no-]expand", "Print expansion") do |e|
    options.expand = e
  end

  opts.on("-g", "--[no-]print-grammar", "Print grammar") do |g|
    options.print_grammar = g
  end

  opts.on("-l", "--lossifiers [ALGO1, ALGO2, ...]", Array,
          "The lossifier algorithms to use") do |algos|
    if algos = [ 'none' ]
      options.algorithms = []
      next
    end

    raise OptionParser::InvalidArgument unless (algos - ALGORITHMS.keys).empty?
    options.algorithms = algos.uniq.map { |algo| ALGORITHMS[algo] }
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

str = File.read(ARGV[0])
cfg = Sequitur.new(str).run

def puts_cfg(cfg, options)
  puts cfg if options.print_grammar
  puts cfg.expand if options.expand
  puts "\n"
end

puts "Sequitur-----------------------------------------------\n\n"
puts_cfg cfg, options

options.algorithms.each do |algo|
  puts algo.name + '-' * (55 - algo.name.size) + "\n\n"
  puts_cfg algo.new(cfg, options.verbose).run, options
end
