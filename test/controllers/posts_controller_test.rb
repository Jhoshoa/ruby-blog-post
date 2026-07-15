require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @alice_post = @alice.posts.create!(title: "Alice's Post", body: "Alice wrote this.", published: true)
    @bob_post = @bob.posts.create!(title: "Bob's Post", body: "Bob wrote this.", published: false)
  end

  # INDEX
  test "should get index without authentication" do
    get posts_path
    assert_response :success
    assert_select "h1", "All Posts"
  end

  test "index does not show New Post button when not signed in" do
    get posts_path
    assert_select "a[href='#{new_post_path}']", count: 0
  end

  test "index shows New Post button when signed in" do
    sign_in_as_user
    get posts_path
    assert_select "a[href='#{new_post_path}']", minimum: 1
  end

  test "index shows author name for each post" do
    get posts_path
    assert_select "p", text: /By Alice/
    assert_select "p", text: /By Bob/
  end

  # SHOW
  test "should get show without authentication" do
    get post_path(@alice_post)
    assert_response :success
    assert_select "h1", @alice_post.title
  end

  test "show displays author name" do
    get post_path(@alice_post)
    assert_select "span.font-medium", text: "Alice"
  end

  # NEW / CREATE
  test "unauthenticated user cannot access new post" do
    get new_post_path
    assert_redirected_to sign_in_path
  end

  test "unauthenticated user cannot create post" do
    assert_no_difference("Post.count") do
      post posts_path, params: { post: { title: "New Post", body: "Content" } }
    end
    assert_redirected_to sign_in_path
  end

  test "authenticated user can create post" do
    sign_in_as_user(@alice)
    assert_difference("Post.count", 1) do
      post posts_path, params: { post: { title: "My New Post", body: "Great content.", published: true } }
    end
    assert_redirected_to post_path(Post.last)
    assert_equal @alice, Post.last.user
  end

  test "authenticated user cannot create post with invalid data" do
    sign_in_as_user(@alice)
    assert_no_difference("Post.count") do
      post posts_path, params: { post: { title: "", body: "" } }
    end
    assert_response :unprocessable_entity
  end

  # EDIT / UPDATE
  test "unauthenticated user cannot access edit" do
    get edit_post_path(@alice_post)
    assert_redirected_to sign_in_path
  end

  test "author can edit their own post" do
    sign_in_as_user(@alice)
    get edit_post_path(@alice_post)
    assert_response :success
  end

  test "non-author cannot edit another user's post" do
    sign_in_as_user(@bob)
    get edit_post_path(@alice_post)
    assert_redirected_to posts_path
    follow_redirect!
    assert_select ".text-red-800", /not authorized/
  end

  test "author can update their own post" do
    sign_in_as_user(@alice)
    patch post_path(@alice_post), params: { post: { title: "Updated Title" } }
    assert_redirected_to post_path(@alice_post)
    @alice_post.reload
    assert_equal "Updated Title", @alice_post.title
  end

  test "non-author cannot update another user's post" do
    sign_in_as_user(@bob)
    patch post_path(@alice_post), params: { post: { title: "Hacked" } }
    assert_redirected_to posts_path
    @alice_post.reload
    assert_equal "Alice's Post", @alice_post.title
  end

  # DESTROY
  test "unauthenticated user cannot delete post" do
    assert_no_difference("Post.count") do
      delete post_path(@alice_post)
    end
    assert_redirected_to sign_in_path
  end

  test "author can delete their own post" do
    sign_in_as_user(@alice)
    assert_difference("Post.count", -1) do
      delete post_path(@alice_post)
    end
    assert_redirected_to posts_path
  end

  test "non-author cannot delete another user's post" do
    sign_in_as_user(@bob)
    assert_no_difference("Post.count") do
      delete post_path(@alice_post)
    end
    assert_redirected_to posts_path
  end
end
