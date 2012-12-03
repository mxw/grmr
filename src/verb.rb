#
# verb.rb - Be a bit verbose.
#

class Verb
  def self.loop(name, v, &blk)
    inner_loop name, v, &blk
    puts "\n" if v
  end

  def self.inner_loop(name, v)
    puts "> " + name + ':' if v
    Kernel.loop.each_with_index do |_, i|
      output = yield
      puts ">   [#{i}]".ljust(10) + output if v
    end
  end
  private_class_method :inner_loop
end
