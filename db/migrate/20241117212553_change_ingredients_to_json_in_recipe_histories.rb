class ChangeIngredientsToJsonInRecipeHistories < ActiveRecord::Migration[7.1]
  def change

    change_column :recipe_histories, :ingredients, :json, default: []
  end
end
