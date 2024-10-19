class RecipesController < ApplicationController
  def index
    @recipe = nil
  end

  def scrape
    require 'open-uri'
    url = params[:url]
    
    # Open the URL and parse the HTML
    doc = Nokogiri::HTML(URI.open(url))
    
    # Example scraping logic (this depends on the structure of the webpage you're scraping)
    title = doc.css('.recipe-title').text.strip rescue "No title found"
    ingredients = doc.css('.ingredients').text.strip rescue "No ingredients found"

    # Create a new Recipe object to pass to the view
    @recipe = Recipe.new(title: title, ingredients: ingredients, instructions: instructions)

    render :index
  end
end
