File.open("data.txt","w") do |f|
  100000.times do |i|
    v = Math.sin(i * Math::PI/80000) * 300 + rand(40) + 280
    v = 0 if v < 0
    v = 600 if v > 600
    f.puts(v.to_i.to_s)
  end
end