require 'uc3-ssm'

puts "hello"
puts Uc3Ssm::ConfigResolver.new.resolve_values('config/database2.yml')
