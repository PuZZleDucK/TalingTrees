# frozen_string_literal: true

max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 2)
threads max_threads_count, max_threads_count

workers ENV.fetch("WEB_CONCURRENCY", 1)
preload_app!

port        ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")
plugin :tmp_restart
