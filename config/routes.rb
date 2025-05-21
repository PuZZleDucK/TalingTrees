Rails.application.routes.draw do
  root 'trees#index'
  resources :trees, only: [:index, :show]
  post 'trees/:id/chat', to: 'chats#create', as: 'tree_chat'
  get  'trees/:id/chat', to: 'chats#history'
  post 'trees/:id/tag', to: 'trees#tag', as: 'tag_tree'
  post 'trees/:id/tag_user', to: 'trees#tag_user', as: 'tag_user'
  post 'select_user', to: 'application#select_user'
  post 'update_location', to: 'application#update_location'
  post 'know_tree/:id', to: 'application#know_tree'
end
