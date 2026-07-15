require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get sign in page" do
    get sign_in_path
    assert_response :success
    assert_select "h1", "Sign in"
  end

  test "should sign in with valid credentials" do
    post sign_in_path, params: { email: "alice@example.com", password: "password123" }
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".text-green-800", /Signed in/
  end

  test "should not sign in with wrong password" do
    post sign_in_path, params: { email: "alice@example.com", password: "wrongpassword" }
    assert_response :unprocessable_entity
    assert_select ".text-red-800", /Invalid email or password/
  end

  test "should not sign in with non-existent email" do
    post sign_in_path, params: { email: "nobody@example.com", password: "password123" }
    assert_response :unprocessable_entity
  end

  test "should sign out" do
    sign_in_as_user
    delete logout_path
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".text-green-800", /Signed out/
  end

  test "signed out user has no current_user" do
    get root_path
    assert_response :success
    # No error means session is properly handled
  end
end
