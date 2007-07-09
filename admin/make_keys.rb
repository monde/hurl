require 'rubygems'
require "#{File.dirname(__FILE__)}/../hurl"

include Base62

begin
  raise if ARGV.length == 0
  pow = ARGV[0].to_i
  raise if pow < 1
rescue
  STDERR.puts "Usage, where power is 1 or greater and will be used as a power of 62:"
  STDERR.puts "ruby #{$0} POWER"
  exit 1
end
pow = pow - 1
table_name = Hurl::Models::Key.table_name
puts "/* creating #{62 ** (pow+1)} keys for the #{table_name} table */;"

#puts "LOCK TABLES \`#{table_name}\` WRITE;"
(pow...pow+1).each do |pow|
  lower = 62 ** pow
  upper = 62 ** (pow+1)
  a = (lower...upper).collect.sort_by { rand }
  values = Array.new
  a.each do |i|
    key = base62_encode(i)
    values << "('#{key}')"
    if i > 61 && i % 1000 == 0 && values.length > 0
      puts "INSERT INTO \`#{table_name}\` (\`key\`) VALUES #{values.join(', ')};"
      values.clear
    end  
  end
  if values.length > 0
    puts "INSERT INTO \`#{table_name}\` (\`key\`) VALUES #{values.join(', ')};"
  end
end
#puts "UNLOCK TABLES;"
