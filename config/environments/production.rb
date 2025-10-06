# frozen_string_literal: true

Rails.application.configure do
  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  config.eager_load = true

  # Ensure secret_key_base is set for verifying signed cookies.
  config.secret_key_base = ENV['SECRET_KEY_BASE'] if ENV['SECRET_KEY_BASE']
  config.active_storage.service = :local

  config.hosts << 'localhost'
  config.hosts << '127.0.0.1'
  config.hosts << '.onrender.com'
end
