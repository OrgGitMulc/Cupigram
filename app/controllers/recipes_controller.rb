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

      if ingredients_heading || needs_heading
        heading = ingredients_heading || needs_heading
      
        # Find the closest following section, div, or ul
        container = heading.xpath("following::section[1] | following::div[1] | following::ul[1]").first
      
        # Process the container if found
        if container
          # Look for ul within the found container
          ul_element = container.at_xpath(".//ul") || container.at_xpath("following::ul[1]")
          li_elements = ul_element.xpath(".//li")
          ul_elements = container.xpath(".//ul")
          
          # Extract items if multiple ul_elements are found
          if ul_elements.any?
            ul_elements.each do |ul_element|
              # Collect the text from each <li> in the current <ul>
              ingredients.concat(ul_element.xpath(".//li").map(&:text))
            end
          # Extract items if ul_element is found
          elsif ul_element
            ingredients = ul_element.xpath(".//li").map(&:text)
          
          elsif li_elements
            ingredients = li_elements.map do |li|
              label = li.at_xpath(".//label")
              label ? label.text.strip : li.text.strip
            end
          else
            # As a fallback, get all li elements directly within the container
            li_elements = container.xpath(".//li").map(&:text)
            ingredients.concat(li_elements) unless li_elements.empty?
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
