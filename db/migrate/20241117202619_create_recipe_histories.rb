class CreateRecipeHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :recipe_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.text :ingredients
      t.string :url

      t.timestamps
    end
  end
end
