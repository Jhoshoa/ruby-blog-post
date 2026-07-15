class CommentsController < ApplicationController
  before_action :require_login
  before_action :set_post
  before_action :set_comment, only: [:destroy]
  before_action :authorize_comment, only: [:destroy]

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to @post, notice: "Comment posted."
    else
      redirect_to @post, alert: "Comment could not be saved. #{@comment.errors.full_messages.to_sentence}"
    end
  end

  def destroy
    @comment.destroy
    redirect_to @post, notice: "Comment deleted."
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def authorize_comment
    unless @comment.editable_by?(Current.user)
      redirect_to @post, alert: "You are not authorized to delete this comment."
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
