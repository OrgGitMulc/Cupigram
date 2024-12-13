require "test_helper"

class ConversionHelperTest < ActionView::TestCase
  include RecipesHelper
  setup do
    User.delete_all
    RecipeHistory.delete_all
  end

  test "converts generic ingredient from metric to us custom" do
    ingredient = { quantity: 1, unit: "cup", ingredient: "rice" }
    assert_equal "236.59g rice", convert_to_metric(ingredient)
  end

  test "converts liquid ingredients to milliliters using density" do
    ingredient = { quantity: 1, unit: "cup", ingredient: "milk" }
    assert_equal "243.69ml milk", convert_to_metric(ingredient)
  end

  test "returns ingredient unchanged if no unit is provided" do
    ingredient = { quantity: 2, ingredient: "eggs" }
    assert_equal "2 eggs", convert_to_metric(ingredient)
  end

  test "converts grams to cups for solids using density" do
    ingredient = { quantity: 120, unit: "g", ingredient: "flour" }
    assert_equal "0.27 cups flour", convert_to_us_custom(ingredient)
  end
end