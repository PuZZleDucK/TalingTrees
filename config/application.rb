# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module TalingTrees
  # Main Rails application class.
  class Application < Rails::Application
    config.load_defaults 7.1
  end
end
