require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create(email: "test@example.com", password: "password")
    @recipe_url = "https://www.allrecipes.com/mini-chicken-pot-pies-recipe-8735456"
    @mock_ingredients = ["1 (8 count) package frozen mini pie shells in foil tins (such as Texas Pie®), thawed", "1refrigerated ready-to-bake pie crust", "414.03g frozen mixed vegetables or frozen peas and carrots","118.29ml water", "1 (5.3-ounce) package soft French cheese, such as Boursin® Garlic and Fine Herbs Cheese, roughly chopped", "114.75ml heavy cream", "414.03g chopped cooked chicken", "2.5g freshly ground black pepper", "salt to taste", "1large egg", "15.0ml water"]

  end

  test "should loginm extract recipe, and save ingredients" do
    post login_url, params: { email: @user.email, password: "password" }
    # note redirect is what happens when user logs in
    assert_response :redirect

    post extract_recipes_url, params: { url: @recipe_url, unit: "metric" }
    assert_response :success

    recipe = RecipeHistory.last
    assert_equal recipe.url, @recipe_url
    assert_equal recipe.ingredients, @mock_ingredients
  end
end