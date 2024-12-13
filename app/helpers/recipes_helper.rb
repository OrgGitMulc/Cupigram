require 'rational'

module RecipesHelper
  UNIT_CONVERSIONS = {
    "cup" => 236.588125, 
    "cups" => 236.588125, 
    "tbsp" => 15,       
    "tablespoon" => 15,    
    "tablespoons" => 15,       
    "tsp" => 5,         
    "teaspoon" => 5,    
    "teaspoons" => 5,        
    "pounds" => 453.6,    
    "pound" => 453.6,    
    "gram" => 0.00422675, 
    "g" => 0.00422675,  
    "ml" => 0.00422675,   
  }.freeze

  DENSITIES = {
    "flour" => 0.53,       # 1 ml of flour = 0.53 grams
    "sugar" => 0.85,       # 1 ml of sugar = 0.85 grams
    "milk" => 1.03,        # 1 ml of milk = 1.03 grams
    "cream" => 0.97,       # 1 ml of cream = 0.97 grams
    "oil" => 0.92          # 1 ml of oil = 0.92 grams
  }.freeze

  # List of liquids that can be converted 
  LIQUIDS = ["water", "milk", "buttermilk", "vegetable oil", "oil", "cream"].freeze

  def parse_quantity(quantity)
    # Ensure quantity is a string before processing
    quantity = quantity.to_s.strip
  
    # check for mixed numbers like "1 3/4"
    if quantity.include?(' ')  
      whole, fraction = quantity.split(' ')
      # Convert the fraction to Rational & then concat to the whole number
      total = whole.to_i + Rational(fraction)
      # to_f converts to a float num, part of the Rational native ruby class
      total.to_f
    # Handle fractions
    elsif quantity.include?('/')  
      Rational(quantity).to_f
    # Handle whole numbers or decimals 
    else  
      quantity.to_f  # Ensure whole numbers or decimals are returned as a Float
    end
  end

  # Helper to convert a parsed ingredient to metric if a unit is present
  def convert_to_metric(parsed_ingredient)
    quantity = parse_quantity(parsed_ingredient[:quantity])
    unit = parsed_ingredient[:unit]&.downcase
    ingredient_name = parsed_ingredient[:ingredient]

    # Find density and liquid status
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
      # Return the original ingredient if no unit
      "#{quantity.round(0)}#{unit} #{ingredient_name}".strip
    end
  end

  # Helper to convert a parsed ingredient to us customary if a unit is present
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
      # Return the original ingredient if no unit
      "#{quantity.round(0)}#{unit} #{ingredient_name}".strip
    end
  end
end
