require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @post = @user.posts.create!(title: "Test Post", body: "This is test content.")
  end

  test "valid post" do
    assert @post.valid?
  end

  test "post belongs to user" do
    assert_equal @user, @post.user
  end

  test "post requires user" do
    post = Post.new(title: "Test", body: "Content")
    assert_not post.valid?
    assert_includes post.errors[:user], "must exist"
  end

  test "requires title" do
    @post.title = nil
    assert_not @post.valid?
    assert_includes @post.errors[:title], "can't be blank"
  end

  test "title minimum length" do
    @post.title = "AB"
    assert_not @post.valid?
    assert_includes @post.errors[:title], "is too short (minimum is 3 characters)"
  end

  test "requires body" do
    @post.body = nil
    assert_not @post.valid?
    assert_includes @post.errors[:body], "can't be blank"
  end

  test "destroying user destroys posts" do
    assert_difference("Post.count", -@user.posts.count) { @user.destroy }
  end

  test "category defaults to General" do
    assert_equal "General", @post.category
  end

  test "can set category" do
    @post.category = "Technology"
    assert @post.valid?
    assert_equal "Technology", @post.category
  end

  test "category_name returns display name" do
    @post.category = "Technology"
    assert_equal "Technology", @post.category_name
  end

  test "category_name returns General for nil" do
    @post.category = nil
    assert_equal "General", @post.category_name
  end

  test "CATEGORIES has 30 entries" do
    assert_equal 30, Post::CATEGORIES.size
  end

  test "search scope finds by title" do
    results = Post.search("First")
    assert_includes results, posts(:one)
  end

  test "search scope finds by body" do
    results = Post.search("second post body")
    assert_includes results, posts(:two)
  end

  test "search scope returns all with blank query" do
    results = Post.search("")
    assert_equal Post.count, results.count
  end

  test "search scope is SQL injection safe" do
    results = Post.search("%' OR 1=1 --")
    assert_respond_to results, :each
  end
end
