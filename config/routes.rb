Craigslytics::Application.routes.draw do
  get "users/login"

  devise_for :users

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

  root :to => 'analyses#home'
  mount Resque::Server, :at => "/resque"
end
