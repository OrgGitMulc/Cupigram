# app/controllers/recipes_controller.rb
require 'nokogiri'
require 'open-uri'

class RecipesController < ApplicationController
  def index
    # Initialize @ingredients to an empty array to avoid nil errors
    @ingredients = []
  end

  def scrape
    # Get the URL from params and set up headers to avoid any 40* errors with the requests
    url = params[:url]
    headers = { "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36" }
    
    # Open the URL dynamically with headers
    begin
      doc = Nokogiri::HTML(URI.open(url, headers))

      # Initialize an empty array to collect ingredients
      ingredients = []

      # Search for the <h*> element that contains "Ingredients"
      ingredients_heading = doc.at_xpath("//*[self::h2 or self::h3 or self::h4][contains(text(), 'Ingredients')]")

      # Search for the <h*> element that contains "What you need" incase it is the title of the ingredients
      needs_heading = doc.xpath("//*[self::h2 or self::h3 or self::h4][contains(text(), 'What you need')]")

      if ingredients_heading 
        section_element = ingredients_heading.xpath("following::section[1]").first

        div_element = ingredients_heading.xpath("following::div[1]").first

        ul_element = ingredients_heading.xpath("following::ul[1]").first

        if section_element
          # Find the <ul> within that section
          ul_element_adj = section_element.xpath("ul").first
          
          if ul_element_adj
            # Extract the text from each <li> within the <ul>
            ingredients = ul_element_adj.xpath("li").map(&:text)
          end

        elsif div_element
          ul_element_adj = div_element.xpath(".//ul").first

          if ul_element_adj
            ingredients = ul_element_adj.xpath(".//li").map(&:text)
          else
            ingredients = div_element.xpath(".//li").map(&:text)
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

    rescue OpenURI::HTTPError => e
      # Handle any HTTP errors
      puts "Error fetching the URL: #{e.message}"
      @ingredients = ["Unable to access the provided URL."]
      render :index
    end
  end
end
