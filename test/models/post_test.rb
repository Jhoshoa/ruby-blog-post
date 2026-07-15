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
end
