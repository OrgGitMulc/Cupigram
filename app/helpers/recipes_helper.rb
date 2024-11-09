# Include the Rational class to handle fractions
require 'rational'

module RecipesHelper
  UNIT_CONVERSIONS = {
    "cup" => 240,       # 1 cup = 240 grams
    "tbsp" => 15,       # 1 tablespoon = 15 grams
    "tsp" => 5,         # 1 teaspoon = 5 grams
    # Add other conversions as needed
  }.freeze

  # Helper to parse quantity with Rational support
  def parse_quantity(quantity)
    if quantity.include?(' ')  # Check for mixed numbers like "1 3/4"
      whole, fraction = quantity.split(' ')
      # Convert the fraction part (e.g., "3/4") to Rational, and add to the whole number
      total = whole.to_i + Rational(fraction)
      total.to_f  # Return as a float
    elsif quantity.include?('/')  # Handle fractions like "1/2"
      Rational(quantity).to_f  # Convert fraction like "1/2" to float
    else  # Handle whole numbers or decimals
      quantity.to_f
    end
  end

  # Helper to convert a parsed ingredient to metric if a unit is present
  def convert_to_metric(parsed_ingredient)
    # Separate parsed data
    quantity = parse_quantity(parsed_ingredient[:quantity])
    unit = parsed_ingredient[:unit]&.downcase
    ingredient_name = parsed_ingredient[:ingredient]

    # Only convert if the unit exists in the conversion table
    if unit && UNIT_CONVERSIONS.key?(unit)
      metric_quantity = quantity * UNIT_CONVERSIONS[unit]
      "#{metric_quantity.round(0)} grams #{ingredient_name}"
    else
      # Return original ingredient if no conversion is applicable
      "#{quantity.round(0)} #{unit} #{ingredient_name}".strip
    end
  end
end
