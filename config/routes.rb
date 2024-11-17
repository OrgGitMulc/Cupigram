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

  # User authentication routes
  resources :users, only: [:new, :create] # For sign-up
  resources :sessions, only: [:new, :create, :destroy] # For log-in/log-out
  
  # Custom routes for authentication
  get 'signup', to: 'users#new', as: :signup
  post "signup", to: "users#create"

  get 'login', to: 'sessions#new', as: :login
  post 'login', to: 'sessions#create'
  
  delete 'logout', to: 'sessions#destroy', as: :logout

  # Defines the root path route ("/")
  root "recipes#index"  # Sets the root path to the recipes index
end
