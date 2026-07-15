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

  test "new post form displays category selector when categories exist" do
    sign_in_as_user(@alice)
    get new_post_path
    assert_response :success
    assert_select "input[type='checkbox'][name*='category_ids']", minimum: 1
  end

  test "new post form does not display category selector when no categories exist" do
    Category.destroy_all
    sign_in_as_user(@alice)
    get new_post_path
    assert_response :success
    assert_select "input[type='checkbox'][name*='category_ids']", count: 0
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
    assert_empty Post.last.categories
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

  # CATEGORIES ON POSTS
  test "authenticated user can create post with categories" do
    category = categories(:technology)
    sign_in_as_user(@alice)
    assert_difference("Post.count", 1) do
      post posts_path, params: { post: { title: "Categorized Post", body: "Content", category_ids: [category.id] } }
    end
    assert_includes Post.last.categories, category
  end

  test "author can update post categories" do
    category = categories(:technology)
    sign_in_as_user(@alice)
    patch post_path(@alice_post), params: { post: { category_ids: [category.id] } }
    assert_redirected_to post_path(@alice_post)
    @alice_post.reload
    assert_includes @alice_post.categories, category
  end

  test "author can remove all categories from post" do
    category = categories(:technology)
    @alice_post.categories << category
    sign_in_as_user(@alice)
    patch post_path(@alice_post), params: { post: { category_ids: [] } }
    @alice_post.reload
    assert_empty @alice_post.categories
  end

  # CATEGORY FILTERING
  test "index filters posts by category slug" do
    category = categories(:technology)
    @alice_post.categories << category

    get posts_path(category: category.slug)
    assert_response :success
    assert_select "h2", text: @alice_post.title
    assert_select "h2", text: @bob_post.title, count: 0
  end

  test "index shows all posts when no category filter" do
    get posts_path
    assert_response :success
    assert_select "h2", text: @alice_post.title
    assert_select "h2", text: @bob_post.title
  end

  test "index shows empty state when filtering by nonexistent category" do
    get posts_path(category: "nonexistent")
    assert_response :success
    assert_select ".grid", count: 0
  end

  # SEARCH
  test "index searches posts by title" do
    get posts_path(q: "Alice")
    assert_response :success
    assert_select "h2", text: "Alice's Post"
    assert_select "h2", text: "Bob's Post", count: 0
  end

  test "index searches posts by body content" do
    get posts_path(q: "Bob wrote")
    assert_response :success
    assert_select "h2", text: "Bob's Post"
    assert_select "h2", text: "Alice's Post", count: 0
  end

  test "index shows empty state when search has no results" do
    get posts_path(q: "nonexistent term xyz")
    assert_response :success
    assert_select ".grid", count: 0
    assert_select "h3", text: "No posts found"
  end

  test "search with empty query returns all posts" do
    get posts_path(q: "")
    assert_response :success
    assert_select "h2", text: "Alice's Post"
    assert_select "h2", text: "Bob's Post"
  end

  test "search displays result count" do
    get posts_path(q: "Alice")
    assert_select "p", text: /1 post found/
  end

  test "search is SQL injection safe" do
    get posts_path(q: "%' OR 1=1 --")
    assert_response :success
  end

  # PAGINATION
  test "index shows pagination nav when more than 12 posts" do
    user = users(:alice)
    13.times { |i| user.posts.create!(title: "Pagy Post #{i}", body: "Content #{i}") }
    get posts_path
    assert_response :success
    assert_select "nav.pagy"
  end

  test "index does not show prev/next links when 12 or fewer posts" do
    get posts_path
    assert_response :success
    assert_select "nav.pagy a[rel='prev']", count: 0
    assert_select "nav.pagy a[rel='next']", count: 0
  end

  test "index respects page parameter" do
    user = users(:alice)
    13.times { |i| user.posts.create!(title: "Page Two Post #{i}", body: "Content #{i}") }
    get posts_path(page: 2)
    assert_response :success
    assert_select "nav.pagy"
  end

  test "category show uses pagination" do
    category = categories(:technology)
    user = users(:alice)
    13.times do |i|
      post = user.posts.create!(title: "Tech #{i}", body: "Content #{i}")
      post.categories << category
    end
    get category_path(category.slug)
    assert_response :success
    assert_select "nav.pagy"
  end
end
