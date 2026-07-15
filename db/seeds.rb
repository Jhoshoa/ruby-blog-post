categories = ["Technology", "Lifestyle", "Travel", "Food", "Health", "Business"]

categories.each do |name|
  Category.find_or_create_by!(name: name)
end

puts "Created #{Category.count} categories"
