# Test Type: Controller Tests
# Ensure the extract method handles valid inputs correctly.
# Test edge cases, such as missing or invalid URLs.
# Verify that recipe histories are saved to the database when logged in.

require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    User.delete_all
    RecipeHistory.delete_all

    @user = User.create!(id: 1, email: "user1@example.com", password: "password")
    @recipe_history = RecipeHistory.create!(id: 1, url: "https://example.com/recipe1", user_id: @user.id, ingredients: [])
  end

  test "extract & convert recipe with valid URL to desired unit" do
    post extract_recipes_url, params: { url: "https://www.allrecipes.com/mini-chicken-pot-pies-recipe-8735456", unit: "metric" }
    assert_response :success
  end

  test "should not extract data without a URL" do
    post extract_recipes_url, params: { unit: "metric" }
    assert_response :redirect
    assert_match "URL & conversion selection is required to extract the recipe.", flash[:alert]
  end

  test "should not extract information without selecting unit" do
    post extract_recipes_url, params: { url: "https://www.allrecipes.com/mini-chicken-pot-pies-recipe-8735456" }
    assert_response :redirect
  end
end
