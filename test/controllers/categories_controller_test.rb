require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @technology = categories(:technology)
    @lifestyle = categories(:lifestyle)
    @post = @user.posts.create!(title: "Tech Post", body: "About technology", published: true)
    @post.categories << @technology
  end

  # INDEX
  test "should get index" do
    get categories_path
    assert_response :success
    assert_select "h1", "Categories"
  end

  test "index lists categories with post counts" do
    get categories_path
    assert_response :success
    assert_select "h2", text: "Technology"
    assert_select "h2", text: "Lifestyle"
    assert_select "p", text: /1 post/
  end

  test "index shows zero posts for categories without posts" do
    get categories_path
    assert_response :success
    assert_select "p", text: /0 posts/
  end

  # SHOW
  test "should get show by slug" do
    get category_path(@technology.slug)
    assert_response :success
    assert_select "h1", "Technology"
  end

  test "show displays posts in category" do
    get category_path(@technology.slug)
    assert_response :success
    assert_select "h2", text: "Tech Post"
  end

  test "show returns 404 for nonexistent slug" do
    get category_path("nonexistent")
    assert_response :not_found
  end

  test "show only displays posts in the category" do
    other_post = @user.posts.create!(title: "Food Post", body: "About food", published: true)
    other_post.categories << @lifestyle

    get category_path(@technology.slug)
    assert_response :success
    assert_select "h2", text: "Tech Post"
    assert_select "h2", text: "Food Post", count: 0
  end

  test "show includes author name" do
    get category_path(@technology.slug)
    assert_response :success
    assert_select "p", text: /By #{@user.name}/
  end

  test "show shows empty state when no posts in category" do
    empty_cat = Category.create!(name: "Empty", slug: "empty")
    get category_path(empty_cat.slug)
    assert_response :success
    assert_select "h3", text: /No posts in this category/
  end
end
