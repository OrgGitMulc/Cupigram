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
    "gram" => 0.00422675,  # Conversion from grams to cups (general solid density)
    "g" => 0.00422675,  # Conversion from grams to cups (general solid density)
    "ml" => 0.00422675,    # Conversion from milliliters to cups (liquids)
  }.freeze

  DENSITIES = {
    "flour" => 0.53,       # 1 ml of flour = 0.53 grams
    "sugar" => 0.85,       # 1 ml of sugar = 0.85 grams
    "milk" => 1.03,        # 1 ml of milk = 1.03 grams
    "cream" => 0.97,       # 1 ml of cream = 0.97 grams
    "oil" => 0.92          # 1 ml of oil = 0.92 grams
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
    quantity = parse_quantity(parsed_ingredient[:quantity])
    unit = parsed_ingredient[:unit]&.downcase
    ingredient_name = parsed_ingredient[:ingredient]

    # Check if the ingredient has a density specified
    # density = DENSITIES[ingredient_name.downcase] if DENSITIES.key?(ingredient_name.downcase)
    density_key = DENSITIES.keys.find { |key| ingredient_name.downcase.include?(key) }
    density = DENSITIES[density_key] if density_key
    is_liquid = LIQUIDS.any? { |liquid| ingredient_name.downcase.include?(liquid) }

    if unit && UNIT_CONVERSIONS.key?(unit)
      if density
        # Convert based on density if density is available for the ingredient
        metric_quantity = quantity * UNIT_CONVERSIONS[unit] * density
        unit_label = is_liquid ? "ml" : "g"  # Set appropriate unit for liquid or solid
        "#{metric_quantity.round(2)}#{unit_label} #{ingredient_name}"
      elsif is_liquid
        # Convert to milliliters for liquids without specific density
        metric_quantity = quantity * UNIT_CONVERSIONS[unit]
        "#{metric_quantity.round(2)}ml #{ingredient_name}"
      else
        # Convert to grams for other solids
        metric_quantity = quantity * UNIT_CONVERSIONS[unit]
        "#{metric_quantity.round(2)}g #{ingredient_name}"
      end
    else
      # Return the original ingredient if no conversion is applicable
      "#{quantity.round(0)} #{unit} #{ingredient_name}".strip
    end
  end

  def convert_to_us_custom(parsed_ingredient)
    quantity = parse_quantity(parsed_ingredient[:quantity])
    unit = parsed_ingredient[:unit]&.downcase
    ingredient_name = parsed_ingredient[:ingredient]
  
    # Find density and liquid status
    density_key = DENSITIES.keys.find { |key| ingredient_name.downcase.include?(key) }
    density = DENSITIES[density_key] if density_key
    is_liquid = LIQUIDS.any? { |liquid| ingredient_name.downcase.include?(liquid) }
  
    if unit && UNIT_CONVERSIONS.key?(unit)
      conversion_factor = UNIT_CONVERSIONS[unit]
  
      if density && !is_liquid
        # Adjust conversion for solid ingredients based on density
        us_quantity = (quantity * density) * conversion_factor
        "#{us_quantity.round(2)} cups #{ingredient_name}"
      elsif is_liquid
        # Convert liquid units
        us_quantity = quantity * conversion_factor
        "#{us_quantity.round(2)} cups #{ingredient_name}"
      else
        # Default conversion if no density or liquid status is found
        us_quantity = quantity * conversion_factor
        "#{us_quantity.round(2)} cups #{ingredient_name}"
      end
  
    else
      # Return original ingredient format if no conversion unit found
      "#{quantity.round(0)} #{unit} #{ingredient_name}".strip
    end
  end
end
