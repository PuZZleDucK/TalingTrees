# frozen_string_literal: true

# config/initializers/assets.rb
Rails.application.config.assets.paths << Rails.root.join('app/assets/builds')
Rails.application.config.assets.css_compressor = nil
