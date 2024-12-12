require 'nokogiri'
require 'open-uri'
require 'set'

class RecipesController < ApplicationController
  include RecipesHelper
  def index
    @ingredients = []
    # Show the parsed ingredients
    @parsed_ingredients = []
  end

  def extract
    if params[:url].blank? || params[:unit].blank?
      flash[:alert] = "URL & conversion selection is required to extract the recipe."
      return redirect_to recipes_path
    end

    @url = params[:url]
    headers = { "User-Agent" => "Mozilla/5.0 (Windows; Intel) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36" }
    begin
      doc = Nokogiri::HTML(URI.open(@url, headers))
      ingredients = extract_ingredients(doc)

      # Render the extracted data
      @ingredients = ingredients
      @parsed_ingredients = parse_existing_ingredients(@ingredients)

    # This code block calls the conversion helper methods found in recipes_helper 
    if params[:unit] == "us_customary"
      @parsed_ingredients = @parsed_ingredients.map do |ingredient|
        # Will only use helpers if ingredients are in a hash
        if ingredient.is_a?(Hash) && ingredient[:unit]
          convert_to_us_custom(ingredient)
        elsif ingredient.is_a?(Hash)
          "#{ingredient[:quantity]} #{ingredient[:ingredient]}".strip
        else
          # if no units, just return raw
          ingredient 
        end
      end
    
    elsif params[:unit] == "metric"
      @parsed_ingredients = @parsed_ingredients.map do |ingredient|
        # Will only use helpers if ingredients are in a hash
        if ingredient.is_a?(Hash) && ingredient[:unit]
          convert_to_metric(ingredient)
        elsif ingredient.is_a?(Hash)
          "#{ingredient[:quantity]} #{ingredient[:ingredient]}".strip 
        else
          # if no units, just return raw
          ingredient 
        end
      end
    
    
    end
    
    if session[:user_id]
      user = User.find(session[:user_id])
      recipe_history = user.recipe_histories.create(
        url: @url, 
        ingredients: @parsed_ingredients # Save as raw data
      )

      if recipe_history.persisted?
        Rails.logger.debug "Recipe history saved successfully!"
      else
        Rails.logger.error "Failed to save recipe history: #{recipe_history.errors.full_messages}"
      end
    end

      render :index
    # if extract method cannot retrieve the URL, or is unable to access it a HTTPError is thrown 
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

    # this targets generic ingredients heading found in most HTML, headers with "Ingredients"
    ingredients_heading = doc.at_xpath("//*[self::h2 or self::h3 or self::h4][contains(text(), 'Ingredients')]")

    # targets ingredients that contain the heading What You Need instead of the ingredients
    needs_heading = doc.xpath("//*[self::h2 or self::h3 or self::h4][contains(text(), 'What you need')]")

    # targets any ingredients that have the ingredients string in any tab based sections
    tabs_heading = ingredients_heading&.xpath("following::section[1] | following::div[1]") ||
              doc.at_css("div.tabbed-list") || 
              doc.at_xpath("//*[contains(@class, 'ingredients') or contains(@class, 'list')]")

    if ingredients_heading || needs_heading
      heading = ingredients_heading || needs_heading
      container = heading.xpath("following::section[1] | following::div[1] | following::ul[1]").first

      if container
        ul_element = container.at_xpath(".//ul") || container.at_xpath("following::ul[1]")
        li_elements = ul_element.xpath(".//li")
        ul_elements = container.xpath(".//ul")

        if ul_element
          ul_element.xpath(".//li").each do |li|
            # add the ingredient to the set
            ingredients.add(li.text.strip)
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
            # removes any info unrelated to ingredient. it's often nutritional info
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

  # takes populated ingredients and calls parse_line func on each one
  def parse_existing_ingredients(ingredients)
    ingredients.map do |ingredient|
      parse_line(ingredient)
    end
  end

  # parses txt and differenciates between quantity, unit & ingredient
  def parse_line(line)
    # regex to capture quantity, optional unit, and ingredient
    match = line.match(/^(?<quantity>\d+\s\d+\/\d+|\d+\/\d+|\d+(\.\d+)?)\s?(?<unit>[a-zA-Z%]+)?\s?(?<ingredient>.+)$/)
  
    if match
      {
        quantity: match[:quantity].strip,
        unit: match[:unit]&.strip, # Only add unit if present
        ingredient: match[:ingredient].strip
      }.compact # Remove any empty values if in hash
    else
      # Return line if it doesn't match the pattern
      { ingredient: line.strip, unit: nil, quantity: nil }
    end
  end
end
