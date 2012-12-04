pchange = 30

str = File.read(ARGV[0])
out_f = File.new("e_"+ARGV[0], "w+")

newstr = str.chars.inject("") do |str, c|
  if rand(pchange)==0
    str << '*'
  else
    str << c
  end
end

out_f.write newstr
out_f.close
