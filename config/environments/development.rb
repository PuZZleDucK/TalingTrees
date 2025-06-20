# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.assets.debug       = false   # no live re-splitting
  config.assets.compile     = false   # don’t compile missing assets on the fly
  config.assets.digest      = true    # generate & expect fingerprinted names
  config.public_file_server.enabled = true # serve files out of public/assets

  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.active_storage.service = :local
end
