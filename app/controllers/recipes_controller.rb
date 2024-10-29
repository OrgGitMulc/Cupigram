# app/controllers/recipes_controller.rb
require 'nokogiri'
require 'open-uri'

class RecipesController < ApplicationController
  def index
    # Initialize @ingredients to an empty array to avoid nil errors
    @ingredients = []
  end

  def scrape
    # Open the URL and parse it with Nokogiri
    url = params[:url]
    doc = Nokogiri::HTML(URI.open(url))

    # Initialize an empty array to collect ingredients
    ingredients = []

    # Search for the <h2> element that contains "Ingredients"
    ingredients_heading = doc.at_xpath("//*[self::h2 or self::h3 or self::h4][contains(text(), 'Ingredients')]")
    needs_heading = doc.xpath("//*[self::h2 or self::h3 or self::h4][contains(text(), 'What you need')]")

    if ingredients_heading 
      # Look for a given adjacent element that contains the <ul> with the ingredients
      section_element = ingredients_heading.xpath("following::section[1]").first
      ul_element = ingredients_heading.xpath("following::ul").first

      if section_element
        # Find the <ul> within that section
        ul_element_adj = section_element.xpath("ul").first
        
        if ul_element_adj
          # Extract the text from each <li> within the <ul>
          ingredients = ul_element_adj.xpath("li").map(&:text)
        end
      
      elsif ul_element
        ingredients = ul_element.xpath("li").map(&:text)
      end

    elsif needs_heading
      ingredients_container = needs_heading.xpath("following::div").first

      if ingredients_container
        ul_element = ingredients_container.xpath("ul").first

        if ul_element
          # Extract the text from each <li> within the <ul>
          ingredients = ul_element.xpath("li").map(&:text)
        end

      end
    
      
    end

    # If no ingredients were found, assign a message
    if ingredients.empty?
      ingredients = ["No ingredients found in the expected format."]
    end

    # Print the ingredients for debugging purposes
    puts "Ingredients: #{ingredients.join(", ")}"

    # Render the scraped data
    @ingredients = ingredients
    render :index
  end
end
