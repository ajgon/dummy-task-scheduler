require 'oj'

module Tasks
  class ApplicationTask
    include Sidekiq::Worker

    def self.interval
      '1m'
    end

    def register
      [counters, gauges, histograms, summaries].each do |metrics|
        metrics.values.each do |gauge|
          Prometheus::Client.registry.register(gauge) unless Prometheus::Client.registry.exist?(gauge.name.to_sym)
        end
      end
    end

    def counters
      {}
    end

    def gauges
      {}
    end

    def histograms
      {}
    end

    def summaries
      {}
    end
  end
end
