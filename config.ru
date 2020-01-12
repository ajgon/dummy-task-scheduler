# config.ru

require File.expand_path('./lib/setup.rb', __dir__)

require 'prometheus/middleware/exporter'
require 'sidekiq/web'
require 'sidekiq-scheduler/web'

use Rack::Deflater
use Prometheus::Middleware::Exporter

run Sidekiq::Web
