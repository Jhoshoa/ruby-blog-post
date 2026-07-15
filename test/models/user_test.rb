require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.new(email: "test@example.com", name: "Test User", password: "password123", password_confirmation: "password123")
  end

  test "valid user with all attributes" do
    assert @user.valid?
  end

  test "requires email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    users(:alice) # ensure fixture loaded
    duplicate = User.new(email: "alice@example.com", name: "Duplicate", password: "password123")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "requires valid email format" do
    @user.email = "not-an-email"
    assert_not @user.valid?
    assert_includes @user.errors[:email], "must be a valid email address"
  end

  test "normalizes email to lowercase and stripped" do
    @user.email = "  TEST@Example.COM  "
    @user.save!
    assert_equal "test@example.com", @user.email
  end

  test "requires name" do
    @user.name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:name], "can't be blank"
  end

  test "name minimum length" do
    @user.name = "A"
    assert_not @user.valid?
    assert_includes @user.errors[:name], "is too short (minimum is 2 characters)"
  end

  test "requires password on create" do
    @user.password = nil
    assert_not @user.valid?
  end

  test "requires password minimum 6 characters" do
    @user.password = "12345"
    assert_not @user.valid?
  end

  test "does not require password on update if not changing it" do
    @user.save!
    @user.name = "Updated Name"
    assert @user.valid?
  end

  test "requires password on update if changing it" do
    @user.save!
    @user.password = "1234"
    assert_not @user.valid?
  end

  test "has_many posts" do
    assert_respond_to @user, :posts
  end

  test "destroying user destroys associated posts" do
    @user.save!
    @user.posts.create!(title: "My Post", body: "Content")
    assert_difference("Post.count", -1) { @user.destroy }
  end

  test "password_digest is set" do
    @user.save!
    assert_not_nil @user.password_digest
  end

  test "authenticate returns user with correct password" do
    @user.save!
    assert_equal @user, @user.authenticate("password123")
  end

  test "authenticate returns false with wrong password" do
    @user.save!
    assert_not @user.authenticate("wrongpassword")
  end
end
