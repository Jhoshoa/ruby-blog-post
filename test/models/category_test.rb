require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "valid category" do
    category = Category.new(name: "Science")
    assert category.valid?
  end

  test "requires name" do
    category = Category.new(name: nil)
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "requires unique name" do
    Category.create!(name: "Unique Name")
    duplicate = Category.new(name: "Unique Name")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "name uniqueness is case insensitive" do
    Category.create!(name: "Case Test")
    duplicate = Category.new(name: "case test")
    assert_not duplicate.valid?
  end

  test "requires slug" do
    category = Category.new(name: "Test")
    category.slug = nil
    category.valid?
    # slug is auto-generated, so this tests the before_validation callback
    assert_not_nil category.slug
  end

  test "generates slug from name" do
    category = Category.create!(name: "My Category")
    assert_equal "my-category", category.slug
  end

  test "generates slug for multi-word name" do
    category = Category.create!(name: "Science & Technology")
    assert_equal "science-technology", category.slug
  end

  test "requires unique slug" do
    Category.create!(name: "Tech")
    duplicate = Category.new(name: "Tech 2", slug: "tech")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "preserves explicit slug" do
    category = Category.new(name: "Technology", slug: "custom-slug")
    category.valid?
    assert_equal "custom-slug", category.slug
  end

  test "has and belongs to many posts" do
    category = categories(:technology)
    assert_respond_to category, :posts
  end

  test "category can have posts" do
    category = Category.create!(name: "Music")
    user = User.create!(email: "test-cat@example.com", name: "Cat User", password: "password123")
    post = user.posts.create!(title: "Music Post", body: "Content about music")
    category.posts << post
    assert_includes category.posts, post
    assert_includes post.categories, category
  end

  test "destroying category does not destroy posts" do
    category = Category.create!(name: "Temp")
    user = User.create!(email: "temp@example.com", name: "Temp", password: "password123")
    post = user.posts.create!(title: "Temp Post", body: "Content")
    category.posts << post
    assert_difference("Category.count", -1) { category.destroy }
    assert Post.exists?(post.id)
  end
end
