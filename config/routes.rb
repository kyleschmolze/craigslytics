Craigslytics::Application.routes.draw do

  devise_for :users

  post "user/request_demo"

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
