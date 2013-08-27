Craigslytics::Application.routes.draw do

  devise_for :users

  post "user_inquiries/request_demo"

  namespace :admin do
    resources :users do
      collection do
        get :dashboard
      end

      member do
        get :run_listings_importer
        get :run_utility_analyses
      end
    end

    resources :listing_importers
  end

  get "listings/utilities"
  get "listings/overview"
  get "listings/utilities/:id", to: "listings#utility"

  resources :listing_imports do
    collection do
      match :poll
    end
  end
  resources :listings
  resources :listing_comparisons
  resources :analyses do
    member do
      match :poll
    end
  end

  
  #root :to => 'listings#index'
  root :to => 'analyses#home'
  mount Resque::Server, :at => "/resque"
end
