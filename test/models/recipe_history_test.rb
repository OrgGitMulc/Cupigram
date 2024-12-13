require "test_helper"

class RecipeHistoryTest < ActiveSupport::TestCase
  setup do
    User.delete_all
    RecipeHistory.delete_all
  end

  test "should save & retrieve a recipe history from a given user" do
    user = User.create(id: 1, email: "user1@example.com", password: "password123")
    recipe_history = RecipeHistory.create!(id: 1, url: "https://validrecipe.com", user_id: user.id, ingredients: ["1g flour"])
    assert_equal "https://validrecipe.com", recipe_history.url
    assert_includes recipe_history.ingredients, "1g flour"
  end
end
