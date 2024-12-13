require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
      User.delete_all
      RecipeHistory.delete_all

      @user = User.create!(id: 1, email: "user1@example.com", password: "password123")
      @recipe_history = RecipeHistory.create!(id: 1, url: "https://example.com/recipe1", user_id: @user.id, ingredients: [])
    end

    test "should be able to navigate to new user" do
      get new_user_url
      assert_response :success
      assert_select "form"
    end
    
    test "should create user" do
      assert_difference("User.count", 1) do
        post users_url, params: { user: { email: "newuser@example.com", password: "password123" } }
      end
      assert_redirected_to root_path
      follow_redirect!
      assert_equal "Account created successfully!", flash[:notice]
    end

    test "should not create user with invalid data" do
      assert_no_difference("User.count") do
        post users_url, params: { user: { email: "", password: "short" } }
      end
      assert_response :success
      assert_select "div.alert", "There was an error creating your account."
    end

    test "should show recipe history for authenticated user" do
      # call helper method for user login
      sign_in_as(@user) 
      get user_url(@user)
      assert_response :success
      # Check if the recipe history list exists
      assert_select "ul" 
    end

    test "should redirect show when not logged in" do
      get user_url(@user)
      assert_redirected_to login_path
    end

    private

    # Helper method for user login
    def sign_in_as(user)
      post login_url, params: { email: user.email, password: "password123" }
      assert_response :redirect
    end
end