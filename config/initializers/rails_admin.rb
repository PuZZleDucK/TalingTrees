# frozen_string_literal: true

RailsAdmin.config do |config|

  config.asset_source = :sprockets

  config.main_app_name = ['TalingTrees', 'Admin']
  config.authenticate_with {} # no authentication for now
  config.current_user_method do
    if respond_to?(:current_user, true)
      current_user
    else
      User.first
    end
  end

  config.included_models = %w[
    Tree
    Suburb
    User
    UserTree
    TreeRelationship
    TreeTag
    UserTag
    Chat
    Message
  ]

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app
  end
end
