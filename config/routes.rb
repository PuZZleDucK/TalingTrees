Rails.application.routes.draw do
  root 'trees#index'
  resources :trees, only: [:index]
  post 'trees/:id/chat', to: 'chats#create', as: 'tree_chat'
  get  'trees/:id/chat', to: 'chats#history'
  post 'select_user', to: 'application#select_user'
end
