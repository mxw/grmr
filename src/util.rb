#
# util.rb - Everybody loves util.
#

#
# Longest common substring implementation adapted from
# http://en.wikibooks.org/wiki/Algorithm_implementation/Strings/Longest_common_substring
#

# Raw string lcs
def lcs(s1, s2)
  m = Array.new(s1.length+1){ [0] * (s2.length+1) }
  longest, x_longest = 0,0
  (1 .. s1.length).each do |x|
    (1 .. s2.length).each do |y|
      if s1[x-1] == s2[y-1]
        m[x][y] = m[x-1][y-1] + 1
        if m[x][y] > longest
          longest = m[x][y]
          x_longest = x
        end
      else
        m[x][y] = 0
      end
    end
  end
  s1[x_longest - longest .. (x_longest-1)]
end
