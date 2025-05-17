Rails.application.routes.draw do
  root 'trees#index'
  resources :trees, only: [:index]
  post 'select_user', to: 'application#select_user'
end
