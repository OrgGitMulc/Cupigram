# Test Type: System Tests
# Test user login with correct and incorrect credentials.
# Ensure flash messages appear for errors.

require "application_system_test_case"

class UserAuthenticationsTest < ApplicationSystemTestCase
  include Capybara::DSL

  setup do
    User.delete_all
    RecipeHistory.delete_all
  end

  test "user can utilize main function without login" do
    visit root_path
    fill_in "https://example.com/recipe", with: "https://www.allrecipes.com/mini-chicken-pot-pies-recipe-8735456"
    choose("unit_metric")
    click_button "Extract Recipe"
    assert_current_path extract_recipes_path
  end

  test "user can log in, perform main function, view recipe history, and logout" do
    user = User.create!(email: "user1@example.com", password: "password")

    visit login_path
    fill_in "exampleFormControlInput1", with: user.email
    fill_in "exampleFormControlTextarea1", with: user.password
    click_button "Login"

    assert_text "Logged in successfully!"
    assert_current_path recipes_path

    fill_in "https://example.com/recipe", with: "https://www.allrecipes.com/mini-chicken-pot-pies-recipe-8735456"
    choose("unit_metric")
    click_button "Extract Recipe"
    assert_current_path extract_recipes_path

    click_link "View Recipe History"
    assert_current_path("/users/#{user.id}")

    click_link "Back"
    click_on "Logout"
    assert_current_path root_path
  end

  test "user cannot login with incorrect details" do
    user = User.create!(email: "user2@example.com", password: "password123")

    visit login_path
    fill_in "exampleFormControlInput1", with: "wrong@email.com"
    fill_in "exampleFormControlTextarea1", with: user.password
    click_button "Login"

    assert_text "Invalid email or password."

    fill_in "exampleFormControlInput1", with: user.email
    fill_in "exampleFormControlTextarea1", with: "wrongpassword"
    click_button "Login"

    assert_text "Invalid email or password."
  end
end
