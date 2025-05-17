Rails.application.routes.draw do
  root 'trees#index'
  resources :trees, only: [:index]
end
