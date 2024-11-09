# app/controllers/recipes_controller.rb
require 'nokogiri'
require 'open-uri'

class RecipesController < ApplicationController
  include RecipesHelper
  def index
    @ingredients = []
    @parsed_ingredients = [] # For storing parsed ingredients separately
  end

  def extract
    url = params[:url]
    headers = { "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36" }
    unit = params[:unit]
    begin
      doc = Nokogiri::HTML(URI.open(url, headers))
      ingredients = extract_ingredients(doc)

      # Print the ingredients for debugging purposes
      puts "Ingredients: #{ingredients.join(" ")}"

      # Render the extracted data
      @ingredients = ingredients
      @parsed_ingredients = parse_existing_ingredients(@ingredients)

      # conversion helpers & logic go here
      puts "Selected unit: #{unit}"

      if unit == "us_customary"
        puts "Convert to US Customary Units"
      elsif params[:unit] == "metric"
        puts "Convert to Metric Units"
        @parsed_ingredients = @parsed_ingredients.map do |ingredient|
          # If it's a hash (it has a unit), process it
        if ingredient.is_a?(Hash)
          if ingredient[:unit] # Only convert if unit exists
            convert_to_metric(ingredient)
          else
            "#{ingredient[:quantity]} #{ingredient[:ingredient]}".strip
          end
        else
          # If it's a string (no unit), just return the ingredient as is
          ingredient
        end
      end
      else
        puts "No units selected"
      end

      render :index

    rescue OpenURI::HTTPError => e
      puts "Error fetching the URL: #{e.message}"
      @ingredients = ["Unable to access the provided URL."]
      render :index
      
    end
  end

  private

  def extract_ingredients(doc)
    ingredients = []

    ingredients_heading = doc.at_xpath("//*[self::h2 or self::h3 or self::h4][contains(text(), 'Ingredients')]")
    needs_heading = doc.xpath("//*[self::h2 or self::h3 or self::h4][contains(text(), 'What you need')]")

    if ingredients_heading || needs_heading
      heading = ingredients_heading || needs_heading
      container = heading.xpath("following::section[1] | following::div[1] | following::ul[1]").first

      if container
        ul_element = container.at_xpath(".//ul") || container.at_xpath("following::ul[1]")
        li_elements = ul_element.xpath(".//li")
        ul_elements = container.xpath(".//ul")

        if ul_elements.any?
          ul_elements.each do |ul_element|
            ingredients.concat(ul_element.xpath(".//li").map(&:text))
          end
        elsif ul_element
          ingredients = ul_element.xpath(".//li").map(&:text)
        elsif li_elements
          ingredients = li_elements.map do |li|
            label = li.at_xpath(".//label")
            label ? label.text.strip : li.text.strip
          end
        else
          li_elements = container.xpath(".//li").map(&:text)
          ingredients.concat(li_elements) unless li_elements.empty?
        end
      end
    end

    ingredients.empty? ? ["No ingredients found in the expected format."] : ingredients
  end

  def parse_existing_ingredients(ingredients)
    ingredients.map do |ingredient|
      parse_line(ingredient)
    end
  end

  def parse_line(line)
    # Adjusted regex to capture quantity, optional unit, and ingredient
    match = line.match(/^(?<quantity>\d+\s\d+\/\d+|\d+\/\d+|\d+(\.\d+)?)\s?(?<unit>[a-zA-Z%]+)?\s?(?<ingredient>.+)$/)
  
    if match
      {
        quantity: match[:quantity].strip,
        unit: match[:unit]&.strip, # Only add `unit` if it’s present
        ingredient: match[:ingredient].strip
      }.compact # Remove any nil values from the hash
    else
      # Return the line as-is if it doesn't match the pattern
      { ingredient: line.strip, unit: nil, quantity: nil }
      # "#{match[:quantity]} #{match[:unit]} #{match[:ingredient]}"
      # line.strip
    end
  end
end
