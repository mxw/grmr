#!/usr/local/bin/ruby

#
# main.rb - Main executable for running experiments.
#

require_relative 'cfg.rb'
require_relative 'list.rb'
require_relative 'lossify.rb'
require_relative 'sequitur.rb'

if ARGV[0].nil?
  puts "Usage: ./lossify input-file"
  exit
end

str = File.read(ARGV[0])

puts "LOSSLESS-----------------------------------------------\n\n"
cfg = Sequitur.new(str).run
puts cfg
puts cfg.expand + "\n"

puts "LOSSY--------------------------------------------------\n\n"
cfg = Lossifier::Similarity.new(cfg).run
puts cfg
puts cfg.expand
