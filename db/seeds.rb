# Categories are now defined as an enum in Post::CATEGORIES
# No database seeding needed for categories.
#
# To set default categories for existing posts:
#   Post.where(category: nil).update_all(category: 0)  # General
#
puts "Categories are defined in Post::CATEGORIES (#{Post::CATEGORIES.size} categories)"
