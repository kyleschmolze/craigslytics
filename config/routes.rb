Craigslytics::Application.routes.draw do
  resources :listings

  resources :analyses do
    member do
      match :poll
    end
  end

  root :to => 'analyses#new'
  mount Resque::Server, :at => "/resque"
end
