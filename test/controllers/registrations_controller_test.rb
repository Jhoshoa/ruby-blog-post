require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get sign up page" do
    get sign_up_path
    assert_response :success
    assert_select "h1", "Create an account"
  end

  test "should register with valid data" do
    assert_difference("User.count", 1) do
      post sign_up_path, params: {
        user: {
          email: "newuser@example.com",
          name: "New User",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".text-green-800", /Welcome/
  end

  test "should not register with empty fields" do
    assert_no_difference("User.count") do
      post sign_up_path, params: {
        user: { email: "", name: "", password: "", password_confirmation: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should not register with short password" do
    assert_no_difference("User.count") do
      post sign_up_path, params: {
        user: {
          email: "test@example.com",
          name: "Test",
          password: "12345",
          password_confirmation: "12345"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should not register with mismatched passwords" do
    assert_no_difference("User.count") do
      post sign_up_path, params: {
        user: {
          email: "test@example.com",
          name: "Test",
          password: "password123",
          password_confirmation: "different123"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should not register with invalid email" do
    assert_no_difference("User.count") do
      post sign_up_path, params: {
        user: {
          email: "not-valid",
          name: "Test",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should not register with duplicate email" do
    assert_no_difference("User.count") do
      post sign_up_path, params: {
        user: {
          email: "alice@example.com",
          name: "Another Alice",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should redirect signed in user from sign up" do
    sign_in_as_user
    get sign_up_path
    assert_redirected_to root_path
  end
end
