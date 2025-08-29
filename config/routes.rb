Rails.application.routes.draw do
  devise_for :users
  root 'pages#home'

  # Static pages
  get 'about', to: 'pages#about'
  get 'contact', to: 'pages#contact'

  # Projects
  resources :projects, only: [:index, :show] do
    member do
      post :vote
    end
  end

  # API routes
  namespace :api do
    namespace :v1 do
      resources :projects, only: [:index, :show, :create] do
        member do
          post :investments
          post :votes
        end
      end
      
      resources :investments, only: [:index, :show]
      resources :votes, only: [:index, :create]
      resources :assistants, only: [:show] do
        member do
          post :ask
        end
      end
      
      resources :payments, only: [] do
        collection do
          post :webhook
        end
      end
      
      resources :resources, only: [:index, :show]
    end
  end

  # Admin routes
  namespace :admin do
    resources :projects
    resources :pools
    get 'dashboard', to: 'dashboard#index'
  end

  # Health check
  get 'health', to: 'application#health'
end

