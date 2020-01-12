# frozen_string_literal: true

max_threads_count = ENV.fetch('MAX_THREADS') { 5 }
min_threads_count = ENV.fetch('MIN_THREADS') { max_threads_count }
threads min_threads_count, max_threads_count

port ENV.fetch('PORT') { 7777 }
pidfile ENV.fetch('PIDFILE') { 'tmp/puma.pid' }

log_requests ENV['LOG_REQUESTS'] == 'true'

workers ENV.fetch("WORKERS") { 2 }
preload_app!
