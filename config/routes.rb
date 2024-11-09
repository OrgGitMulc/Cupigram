Rails.application.routes.draw do
  # Routes for the recipes controller
  resources :recipes do
    collection do
      post 'extract', to: 'recipes#extract'  # Handles scraping from a given URL
    end
  end
  
  # Explicitly define the index route, though this is not necessary since 'resources :recipes' already provides it.
  get 'recipes/index'  # Optional: This can be removed if you're only using the index as the root.

  # Health check route for monitoring application status
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "recipes#index"  # Sets the root path to the recipes index
end
