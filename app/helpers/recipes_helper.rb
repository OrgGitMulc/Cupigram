require 'rational'

module RecipesHelper
  UNIT_CONVERSIONS = {
    "cup" => 240,       # 1 cup = 240 grams
    "cups" => 240,       # 1 cup = 240 grams
    "tbsp" => 15,       # 1 tablespoon = 15 grams
    "tablespoon" => 15,       # 1 tablespoon = 15 grams
    "tablespoons" => 15,       # 1 tablespoon = 15 grams
    "tsp" => 5,         # 1 teaspoon = 5 grams
    "teaspoon" => 5,         # 1 teaspoon = 5 grams
    "teaspoons" => 5,        # 1 teaspoon = 5 grams
    "pounds" => 453.6,    # 1 pound = 453.6 grams
    "pound" => 453.6,    # 1 pound = 453.6 grams
    # Add other conversions as needed
  }.freeze

  # List of liquids that should be converted to milliliters
  LIQUIDS = ["water", "milk", "buttermilk", "vegetable oil", "oil", "cream"].freeze

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
      Rational(quantity).to_f
    end
  end

  # Helper to convert a parsed ingredient to metric if a unit is present
  def convert_to_metric(parsed_ingredient)
    # Separate parsed data
    quantity = parse_quantity(parsed_ingredient[:quantity])
    unit = parsed_ingredient[:unit]&.downcase
    ingredient_name = parsed_ingredient[:ingredient]

    # Determine if the ingredient is a liquid
    is_liquid = LIQUIDS.any? { |liquid| ingredient_name.downcase.include?(liquid) }

    # Only convert if the unit exists in the conversion table
    if unit && UNIT_CONVERSIONS.key?(unit)
      if is_liquid
        # Convert to milliliters for liquids
        metric_quantity = quantity * UNIT_CONVERSIONS[unit]
        "#{metric_quantity.round(2)}ml #{ingredient_name}"
      else
        # Convert to grams for solids
        metric_quantity = quantity * UNIT_CONVERSIONS[unit]
        "#{metric_quantity.round(2)}g #{ingredient_name}"
      end
    else
      # Return original ingredient if no conversion is applicable
      "#{quantity.round(0)} #{unit} #{ingredient_name}".strip
    end
  end
end
