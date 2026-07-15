require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @alice_post = posts(:one)
    @bob_post = posts(:two)
  end

  # CREATE
  test "unauthenticated user cannot create comment" do
    assert_no_difference("Comment.count") do
      post post_comments_path(@alice_post), params: { comment: { body: "Great post!" } }
    end
    assert_redirected_to sign_in_path
  end

  test "authenticated user can create comment" do
    sign_in_as_user(@alice)
    assert_difference("Comment.count", 1) do
      post post_comments_path(@alice_post), params: { comment: { body: "Nice work!" } }
    end
    assert_redirected_to @alice_post
    follow_redirect!
    assert_select ".text-green-800", /Comment posted/
  end

  test "comment is associated with the correct user" do
    sign_in_as_user(@alice)
    post post_comments_path(@alice_post), params: { comment: { body: "My comment" } }
    assert_equal @alice, Comment.last.user
  end

  test "comment is associated with the correct post" do
    sign_in_as_user(@alice)
    post post_comments_path(@alice_post), params: { comment: { body: "My comment" } }
    assert_equal @alice_post, Comment.last.post
  end

  test "cannot create comment with blank body" do
    sign_in_as_user(@alice)
    assert_no_difference("Comment.count") do
      post post_comments_path(@alice_post), params: { comment: { body: "" } }
    end
    assert_redirected_to @alice_post
    follow_redirect!
    assert_select ".text-red-800", /Comment could not be saved/
  end

  test "cannot create comment with body exceeding 1000 chars" do
    sign_in_as_user(@alice)
    assert_no_difference("Comment.count") do
      post post_comments_path(@alice_post), params: { comment: { body: "x" * 1001 } }
    end
    assert_redirected_to @alice_post
  end

  # DESTROY
  test "unauthenticated user cannot delete comment" do
    comment = comments(:alice_on_two)
    assert_no_difference("Comment.count") do
      delete post_comment_path(@bob_post, comment)
    end
    assert_redirected_to sign_in_path
  end

  test "comment author can delete their own comment" do
    comment = comments(:alice_on_two)
    sign_in_as_user(@alice)
    assert_difference("Comment.count", -1) do
      delete post_comment_path(@bob_post, comment)
    end
    assert_redirected_to @bob_post
    follow_redirect!
    assert_select ".text-green-800", /Comment deleted/
  end

  test "post author can delete comments on their post" do
    comment = comments(:alice_on_two)
    sign_in_as_user(@bob)
    assert_difference("Comment.count", -1) do
      delete post_comment_path(@bob_post, comment)
    end
    assert_redirected_to @bob_post
  end

  test "unauthorized user cannot delete comment" do
    comment = comments(:alice_on_two)
    other_user = User.create!(email: "other@example.com", name: "Other", password: "password123")
    sign_in_as_user(other_user)
    assert_no_difference("Comment.count") do
      delete post_comment_path(@bob_post, comment)
    end
    assert_redirected_to @bob_post
    follow_redirect!
    assert_select ".text-red-800", /not authorized/
  end

  test "cannot delete nonexistent comment" do
    sign_in_as_user(@alice)
    assert_no_difference("Comment.count") do
      delete post_comment_path(@alice_post, id: 0)
    end
  end

  test "comment count updates on post show page" do
    sign_in_as_user(@alice)
    get post_path(@alice_post)
    initial_count = Comment.where(post: @alice_post).count

    post post_comments_path(@alice_post), params: { comment: { body: "New one" } }
    get post_path(@alice_post)
    assert_select "h2", text: "Comments (#{initial_count + 1})"
  end
end
