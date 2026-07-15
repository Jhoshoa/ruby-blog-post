ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    fixtures :users, :posts, :comments
  end
end

module ActionDispatch
  class IntegrationTest
    private

    def sign_in_as(user, password: "password123")
      post sign_in_path, params: { email: user.email, password: password }
    end

    def sign_in_as_user(user = nil)
      user ||= users(:alice)
      sign_in_as(user)
    end
  end
end
