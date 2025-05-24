# frozen_string_literal: true

Rails.application.configure do
  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!

  config.cache_classes = true
  config.eager_load = false
end
