module Tasks
  class AqicnTask < ApplicationTask

    URL = 'https://api.waqi.info/'
    METRICS = {
      co: 'CO',
      no2: 'NO2',
      o3: 'O3',
      pm10: 'PM10',
      pm25: 'PM2,5',
      so2: 'SO2'
    }

    def perform
      cities.each do |city|
        result = Oj.load(::Faraday.get("https://api.waqi.info/feed/#{city}/?token=#{token}").body)

        gauges[:aqi].set(result['data']['aqi'].to_f, labels: { city: city })

        METRICS.each do |metric, _|
          metric_data = result.dig('data', 'iaqi', metric.to_s, 'v')
          gauges[metric].set(metric_data.to_f, labels: { city: city }) if metric_data
        end
      end
    end

    def self.interval
      '5m'
    end

    private

    def gauges
      return @gauges if defined?(@gauges)

      @gauges = {
        aqi: Prometheus::Client::Gauge.new(:aqicn_aqi, docstring: 'Air quality index', labels: [:city])
      }

      METRICS.each do |metric, desc|
        @gauges[metric] = Prometheus::Client::Gauge.new(:"aqicn_#{metric}", docstring: desc, labels: [:city])
      end

      @gauges
    end

    def cities
      @cities ||= ENV.fetch('TASK_AQICN_CITIES').split(',').map(&:strip)
    end

    def token
      @token ||= ENV.fetch('TASK_AQICN_TOKEN')
    end
  end
end
