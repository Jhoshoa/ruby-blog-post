class RegistrationsController < ApplicationController
  def new
    redirect_to root_path, notice: "You are already signed in." if user_signed_in?
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      sign_in(@user)
      redirect_to stored_location_or(root_path), notice: "Welcome! Your account has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :name, :password, :password_confirmation)
  end
end
