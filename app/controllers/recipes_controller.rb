# app/controllers/recipes_controller.rb
require 'nokogiri'
require 'open-uri'

class RecipesController < ApplicationController
  def index
    @ingredients = []
    @parsed_ingredients = [] # For storing parsed ingredients separately
  end

  def scrape
    url = params[:url]
    headers = { "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36" }
    
    begin
      doc = Nokogiri::HTML(URI.open(url, headers))
      ingredients = extract_ingredients(doc)

      # Print the ingredients for debugging purposes
      puts "Ingredients: #{ingredients.join(", ")}"

      # Render the scraped data
      @ingredients = ingredients
      @parsed_ingredients = parse_existing_ingredients(@ingredients)
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

    # Your existing ingredient extraction logic...
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
    match = line.match(/(?<quantity>\d+(\.\d+)?)\s?(?<unit>[a-zA-Z%]+)?\s(?<ingredient>.*?)(\((?<alt_quantity>[\d\s\w;]+)\))?/)
    
    if match
      "#{match[:quantity]} #{match[:unit]} #{match[:ingredient]}".strip
    else
      line.strip
    end
  end
end
