#
# verb.rb - Be a bit verbose.
#

def verb_loop(name, v, &blk)
  begin
    puts "> " + name + ':' if v
    Kernel.loop.each_with_index do |_, i|
      output = yield
      puts ">   [#{i}]".ljust(10) + output if v
    end
  ensure
    puts "\n" if v
  end
end
