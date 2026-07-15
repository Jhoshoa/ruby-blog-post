module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
    helper_method :current_user, :user_signed_in?
  end

  private

  def current_user
    Current.user ||= find_user_from_session
  end

  def user_signed_in?
    current_user.present?
  end

  def require_login
    unless user_signed_in?
      store_location
      redirect_to sign_in_path, alert: "You must be signed in to continue."
    end
  end

  def sign_in(user)
    reset_session
    session[:user_id] = user.id
    Current.user = user
  end

  def sign_out
    reset_session
    Current.user = nil
  end

  def store_location
    session[:return_to] = request.fullpath if request.get?
  end

  def stored_location_or(default)
    session.delete(:return_to) || default
  end

  def set_current_user
    Current.user = find_user_from_session
  end

  def find_user_from_session
    User.find_by(id: session[:user_id]) if session[:user_id]
  end
end
