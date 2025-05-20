Rails.application.routes.draw do
  root 'trees#index'
  resources :trees, only: [:index]
  post 'trees/:id/chat', to: 'chats#create', as: 'tree_chat'
  get  'trees/:id/chat', to: 'chats#history'
  post 'select_user', to: 'application#select_user'
  post 'update_location', to: 'application#update_location'
  post 'know_tree/:id', to: 'application#know_tree'
end
