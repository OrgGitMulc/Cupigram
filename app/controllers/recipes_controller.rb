# app/controllers/recipes_controller.rb
require 'nokogiri'
require 'open-uri'
require 'set'

class RecipesController < ApplicationController
  include RecipesHelper
  def index
    @ingredients = []
    @parsed_ingredients = [] # For storing parsed ingredients separately
  end

  def extract
    if params[:url].blank?
      flash[:alert] = "URL is required to extract the recipe."
      return redirect_to recipes_path  # Or render :index if you prefer not to redirect
    end

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

    if params[:unit] == "us_customary"
      puts "Convert to US Customary Units"
      @parsed_ingredients = @parsed_ingredients.map do |ingredient|
        if ingredient.is_a?(Hash) && ingredient[:unit] # Process only if it's a hash and has a unit
          convert_to_us_custom(ingredient)
        elsif ingredient.is_a?(Hash)
          "#{ingredient[:quantity]} #{ingredient[:ingredient]}".strip # If it's a hash without a unit
        else
          ingredient # If it's a string, return as is
        end
      end
    
    elsif params[:unit] == "metric"
      puts "Convert to Metric Units"
      @parsed_ingredients = @parsed_ingredients.map do |ingredient|
        if ingredient.is_a?(Hash) && ingredient[:unit] # Process only if it's a hash and has a unit
          convert_to_metric(ingredient)
        elsif ingredient.is_a?(Hash)
          "#{ingredient[:quantity]} #{ingredient[:ingredient]}".strip # If it's a hash without a unit
        else
          ingredient # If it's a string, return as is
        end
      end
    
    else
      puts "No units selected"
    end
    
    if session[:user_id]
      user = User.find(session[:user_id])
      recipe_history = user.recipe_histories.create(
        url: url, 
        ingredients: @parsed_ingredients # Save as raw data
      )

      if recipe_history.persisted?
        Rails.logger.debug "Recipe history saved successfully!"
      else
        Rails.logger.error "Failed to save recipe history: #{recipe_history.errors.full_messages}"
      end
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
    # Convert to set, easier to manipulate and concat
    ingredients = Set.new

    # this targets generic ingredients heading found in most HTML 
    ingredients_heading = doc.at_xpath("//*[self::h2 or self::h3 or self::h4][contains(text(), 'Ingredients')]")

    # targets ingredients that conmtain the heading What You Need instead of the ingredients
    needs_heading = doc.xpath("//*[self::h2 or self::h3 or self::h4][contains(text(), 'What you need')]")

    # targets any ingredients that have the ingredients string in any tab based sections
    tabs_heading = ingredients_heading&.xpath("following::section[1] | following::div[1]") ||
              doc.at_css("div.tabbed-list") ||  # fallback to specific known structures
              doc.at_xpath("//*[contains(@class, 'ingredients') or contains(@class, 'list')]")

    if ingredients_heading || needs_heading
      heading = ingredients_heading || needs_heading
      container = heading.xpath("following::section[1] | following::div[1] | following::ul[1]").first

      if container
        ul_element = container.at_xpath(".//ul") || container.at_xpath("following::ul[1]")
        li_elements = ul_element.xpath(".//li")
        ul_elements = container.xpath(".//ul")

        if ul_elements.any?
          ul_elements.each do |ul_element|
            ul_element.xpath(".//li").each do |li|
              ingredients.add(li.text.strip)  # Add ingredient to the Set
            end
          end
        elsif ul_element
          ul_element.xpath(".//li").each do |li|
            ingredients.add(li.text.strip)  # Add ingredient to the Set
          end
        elsif li_elements
          li_elements.each do |li|
            label = li.at_xpath(".//label")
            label ? ingredients.add(label.text.strip) : ingredients.add(li.text.strip)
          end
        else
          li_elements = container.xpath(".//li").map(&:text)
          ingredients.concat(li_elements) unless li_elements.empty?
        end
      end
    end

    if tabs_heading

      tabs_heading.each do |tab|
        ul_elements = tabs_heading.xpath(".//ul")
    
        ul_elements.each do |ul_element|
          ul_element.xpath(".//li").each do |li|
            text = li.text.strip
            # removes any nutrional info that may be extracted
            unless text =~ /kcal|fat|saturates|carbs|sugars|fibre|protein|salt/i
              ingredients.add(text)
            end
          end
        end
      end
    end


    # If ingredients empty populate with error msg, else convert set to an array for helper functions
    ingredients.empty? ? ["No ingredients found in the expected format."] : ingredients.to_a
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
