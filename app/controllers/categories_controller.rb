class CategoriesController < ApplicationController
  def index
    @categories = Category.left_joins(:posts).select("categories.*, COUNT(posts.id) AS posts_count").group("categories.id").order(:name)
  end

  def show
    @category = Category.find_by!(slug: params[:slug])
    posts = @category.posts.includes(:user, :categories).order(created_at: :desc)
    @pagy, @posts = pagy(:offset, posts, limit: 12)
  end
end
