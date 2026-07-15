class SessionsController < ApplicationController
  def new
    redirect_to root_path, notice: "You are already signed in." if user_signed_in?
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      sign_in(user)
      redirect_to stored_location_or(root_path), notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to root_path, notice: "Signed out successfully."
  end
end
