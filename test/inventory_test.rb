require_relative '../src/lib/inventory'

inventory = Inventory.new

inventory.get_host_data.each do |row|
  puts row.join(",")
end
  
inventory.get_system_data.each do |row|
  puts row.join(",")
end

