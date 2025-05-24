# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module TalingTrees
  # Main Rails application class.
  class Application < Rails::Application
    config.load_defaults 7.1

    # remove www-static stack
    config.middleware.delete Rack::Sendfile
    config.middleware.delete ActionDispatch::Static

    # remove session/cookie stack
    config.middleware.delete ActionDispatch::Cookies
    config.middleware.delete ActionDispatch::Session::CookieStore
    config.middleware.delete ActionDispatch::Flash

    # remove exception rendering
    # config.middleware.delete ActionDispatch::ShowExceptions
    config.middleware.delete ActionDispatch::DebugExceptions

    # remove policies if you’re not using them
    config.middleware.delete ActionDispatch::ContentSecurityPolicy::Middleware
    config.middleware.delete ActionDispatch::PermissionsPolicy::Middleware

    # remove temp file cleanup
    # config.middleware.delete Rack::TempfileReaper
  end
end
