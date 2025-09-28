# frozen_string_literal: true

Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount Blazer::Engine, at: '/blazer'

  root 'trees#index'
  resources :trees, only: %i[index show]
  post 'trees/:id/chat', to: 'chats#create', as: 'tree_chat'
  get  'trees/:id/chat', to: 'chats#history'
  post 'trees/:id/tag', to: 'trees#tag', as: 'tag_tree'
  delete 'trees/:id/tag', to: 'trees#untag', as: 'untag_tree'
  post 'trees/:id/tag_user', to: 'trees#tag_user', as: 'tag_user'
  post 'select_user', to: 'application#select_user'
  post 'update_location', to: 'application#update_location'
  post 'know_tree/:id', to: 'application#know_tree'
  resources :suburbs, only: [:index]
  resources :points_of_interest, only: [:index]
end
