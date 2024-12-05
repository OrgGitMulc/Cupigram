# Test Type: Model Tests
# Create and validate unique email.
# Ensure password is encrypted and saved correctly.

require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    User.delete_all
    RecipeHistory.delete_all
  end

  test "should validate unique email" do
    user = User.create!(id: 1, email: "user1@example.com", password: "password")
    duplicate_user = User.create(email: user.email, password: user.password)
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "should create encrypted password" do
    user = User.create(email: "user2@example.com", password: "password123")
    assert user.authenticate("password123")
  end
end
