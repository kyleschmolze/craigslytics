Craigslytics::Application.routes.draw do
  resources :analyses, :listings
  root :to => 'analyses#new'
end
