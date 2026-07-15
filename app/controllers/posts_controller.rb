class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :require_login, only: [:new, :create, :edit, :update, :destroy]
  before_action :authorize_post, only: [:edit, :update, :destroy]

  def index
    @posts = Post.includes(:user).order(created_at: :desc)
  end

  def show
  end

  def new
    @post = Current.user.posts.build
  end

  def edit
  end

  def create
    @post = Current.user.posts.build(post_params)

    if @post.save
      redirect_to @post, notice: "Post was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "Post was deleted."
  end

  private

  def set_post
    @post = Post.includes(:user).find(params[:id])
  end

  def authorize_post
    unless @post.user == Current.user
      redirect_to posts_path, alert: "You are not authorized to perform this action."
    end
  end

  def post_params
    params.require(:post).permit(:title, :body, :published, :image)
  end
end
