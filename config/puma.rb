# frozen_string_literal: true

max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 1)
threads max_threads_count, max_threads_count

# Default to Puma's single-mode to avoid the overhead of cluster mode
# unless explicitly configured. This prevents warnings about running
# cluster mode with a single worker.
workers ENV.fetch('WEB_CONCURRENCY', 0)
preload_app!

port        ENV.fetch('PORT', 3000)
environment ENV.fetch('RAILS_ENV', 'development')
plugin :tmp_restart
