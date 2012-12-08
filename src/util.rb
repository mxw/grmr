#
# util.rb - Everybody loves util.
#

class String
  def indent(n, char=' ')
    (char * n) + gsub(/(\n+)/) { $1 + (char * n) }
  end
end
