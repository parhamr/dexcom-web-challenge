#!/usr/bin/ruby
data = []
File.open('data.txt','r') do |f|
  f.each_line do |l|
    data << l.to_i
    if data.length >= 4
      q = data.size / 4.0
      ys = data.sort[q.ceil-1..(3*q).floor]
      factor = q - (ys.size/2.0 - 1)

      mean = (ys[1...-1].inject(0, :+) + (ys[0] + ys[-1]) * factor) / (2*q)
      puts "#{data.length}: #{"%.2f" % mean}"
    end
  end
end
