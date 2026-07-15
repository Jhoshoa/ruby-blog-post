require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @post = posts(:one)
  end

  test "valid comment" do
    comment = Comment.new(body: "Great post!", user: @user, post: @post)
    assert comment.valid?
  end

  test "requires body" do
    comment = Comment.new(body: nil, user: @user, post: @post)
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "requires user" do
    comment = Comment.new(body: "Nice!", user: nil, post: @post)
    assert_not comment.valid?
    assert_includes comment.errors[:user], "must exist"
  end

  test "requires post" do
    comment = Comment.new(body: "Nice!", user: @user, post: nil)
    assert_not comment.valid?
    assert_includes comment.errors[:post], "must exist"
  end

  test "body max length is 1000" do
    comment = Comment.new(body: "x" * 1001, user: @user, post: @post)
    assert_not comment.valid?
    assert_includes comment.errors[:body], "is too long (maximum is 1000 characters)"
  end

  test "body at max length is valid" do
    comment = Comment.new(body: "x" * 1000, user: @user, post: @post)
    assert comment.valid?
  end

  test "belongs to user" do
    comment = comments(:alice_on_two)
    assert_equal @user, comment.user
  end

  test "belongs to post" do
    comment = comments(:alice_on_two)
    assert_equal posts(:two), comment.post
  end

  test "destroying post destroys comments" do
    post = posts(:one)
    post.comments.create!(body: "Temp comment", user: @user)
    assert_difference("Comment.count", -post.comments.count) { post.destroy }
  end

  test "recent scope orders by created_at desc" do
    comment1 = @post.comments.create!(body: "First", user: @user)
    comment2 = @post.comments.create!(body: "Second", user: @user)
    recent_comments = @post.comments.recent
    assert_equal comment2, recent_comments.first
    assert recent_comments.index(comment2) < recent_comments.index(comment1)
  end

  test "editable_by returns true for comment author" do
    comment = comments(:alice_on_two)
    assert comment.editable_by?(@user)
  end

  test "editable_by returns true for post author" do
    comment = comments(:alice_on_two)
    post_author = users(:bob)
    assert comment.editable_by?(post_author)
  end

  test "editable_by returns false for other users" do
    comment = comments(:alice_on_two)
    other_user = User.create!(email: "other@example.com", name: "Other", password: "password123")
    assert_not comment.editable_by?(other_user)
  end

  test "counter cache increments comments_count on post" do
    post = posts(:one)
    initial_count = post.comments_count
    post.comments.create!(body: "New comment", user: @user)
    post.reload
    assert_equal initial_count + 1, post.comments_count
  end

  test "counter cache decrements comments_count on comment deletion" do
    comment = comments(:bob_on_one)
    post = comment.post
    initial_count = post.comments_count
    comment.destroy
    post.reload
    assert_equal initial_count - 1, post.comments_count
  end
end
