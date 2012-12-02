#
# util.rb - Everybody loves util.
#

#
# Longest common substring implementation taken from
# http://rosettacode.org/wiki/Longest_Common_Subsequence#Ruby
#
def lcs(a, b)
  lengths = Array.new(a.size + 1) { Array.new(b.size + 1) { 0 } }

  # Row 0 and column 0 are initialized to 0 already.
  a.split('').each_with_index do |x, i|
    b.split('').each_with_index do |y, j|
      if x == y
        lengths[i+1][j+1] = lengths[i][j] + 1
      else
        lengths[i+1][j+1] = [lengths[i+1][j], lengths[i][j+1]].max
      end
    end
  end

  # Read the substring out from the matrix.
  result = ""
  x, y = a.size, b.size

  while x != 0 and y != 0
    if lengths[x][y] == lengths[x-1][y]
      x -= 1
    elsif lengths[x][y] == lengths[x][y-1]
      y -= 1
    else
      # Assert a[x-1] == b[y-1]
      result << a[x-1]
      x -= 1
      y -= 1
    end
  end

  result.reverse
end
