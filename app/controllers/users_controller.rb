class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:show]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      session[:user_id] = @user.id # Log in user upon sign-up
      redirect_to root_path, notice: "Account created successfully!"
    else
      flash.now[:alert] = "There was an error creating your account."
      render :new
    end
  end

  def show
    @recipe_histories = current_user.recipe_histories
    @output_buffer = ""
  
    @recipe_histories.each do |recipe_history|
      # Ensure ingredients is a valid array
      ingredients = recipe_history.ingredients.is_a?(Array) ? recipe_history.ingredients : []
  
      ingredients.each do |ingredient|
        if ingredient.is_a?(Hash)
          # Safely access keys for hashes
          quantity = ingredient[:quantity].to_s
          unit = ingredient[:unit].to_s
          ingredient_name = ingredient[:ingredient].to_s
        elsif ingredient.is_a?(String)
          # Handle string case
          quantity = ""
          unit = ""
          ingredient_name = ingredient
        else
          # Skip unrecognized types
          next
        end
  
        # Append the ingredient data to @output_buffer using string concatenation
        @output_buffer += "<li>#{quantity} #{unit} #{ingredient_name}</li>"
      end
    end
  end
  
  
  

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
