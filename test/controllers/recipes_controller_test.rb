require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    User.delete_all
    RecipeHistory.delete_all

    @user = User.create!(id: 1, email: "user1@example.com", password_digest: "password")
    @recipe_history = RecipeHistory.create!(id: 1, url: "https://example.com/recipe1", user_id: @user.id, ingredients: [])
  end

  test "extract & convert recipe with valid URL to desired unit" do
    post extract_recipes_url, params: { url: "https://www.allrecipes.com/mini-chicken-pot-pies-recipe-8735456", unit: "metric" }
    assert_response :success
  end
end
