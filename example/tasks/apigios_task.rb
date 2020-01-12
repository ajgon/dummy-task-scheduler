module Tasks
  class ApiGIOSTask < ApplicationTask

    URL = 'https://api.waqi.info/'
    METRICS = {
      AQI: 'Air quality index',
      PM25: 'Pył zawieszony PM2,5',
      PM10: 'Pył zawieszony PM10',
      CO: 'Tlenek węgla',
      NO2: 'Dwutlenek azotu',
      O3: 'Ozon',
      SO2: 'Dwutlenek siarki'
    }

    EPA_BREAKPOINTS = {
      PM25: {
        (0..12.0) => { period: 24 * 60 * 60, aqi: (0..50) },
        (12.0001..35.4) => { period: 24 * 60 * 60, aqi: (51..100) },
        (35.4001..55.4) => { period: 24 * 60 * 60, aqi: (101..150) },
        (55.4001..150.4) => { period: 24 * 60 * 60, aqi: (151..200) },
        (150.4001..250.4) => { period: 24 * 60 * 60, aqi: (201..300) },
        (250.4001..350.4) => { period: 24 * 60 * 60, aqi: (301..400) },
        (350.4001..500.4) => { period: 24 * 60 * 60, aqi: (400..500) }
      },
      PM10: {
        (0..54.0) => { period: 24 * 60 * 60, aqi: (0..50) },
        (54.0001..154.0) => { period: 24 * 60 * 60, aqi: (51..100) },
        (154.0001..254.0) => { period: 24 * 60 * 60, aqi: (101..150) },
        (254.0001..354.0) => { period: 24 * 60 * 60, aqi: (151..200) },
        (354.0001..424.0) => { period: 24 * 60 * 60, aqi: (201..300) },
        (424.0001..504.0) => { period: 24 * 60 * 60, aqi: (301..400) },
        (504.0001..604.0) => { period: 24 * 60 * 60, aqi: (401..500) }
      },
      CO: {
        (0..5038) => { period: 8 * 60 * 60, aqi: (0..50) },
        (5038.0001..10763) => { period: 8 * 60 * 60, aqi: (51..100) },
        (10763.0001..14198) => { period: 8 * 60 * 60, aqi: (101..150) },
        (14198.0001..17633) => { period: 8 * 60 * 60, aqi: (151..200) },
        (17633.0001..34808) => { period: 8 * 60 * 60, aqi: (201..300) },
        (34808.0001..46258) => { period: 8 * 60 * 60, aqi: (301..400) },
        (46258.000..57708) => { period: 8 * 60 * 60, aqi: (401..500) }
      },
      NO2: {
        (0..99.64) => { period: 1 * 60 * 60, aqi: (0..50) },
        (99.6401..188) => { period: 1 * 60 * 60, aqi: (51..100) },
        (188.0001..676.8) => { period: 1 * 60 * 60, aqi: (101..150) },
        (676.8001..1220.12) => { period: 1 * 60 * 60, aqi: (151..200) },
        (1220.1201..2348.12) => { period: 1 * 60 * 60, aqi: (201..300) },
        (2348.1201..3100.12) => { period: 1 * 60 * 60, aqi: (301..400) },
        (3852.1201..3852.12) => { period: 1 * 60 * 60, aqi: (401..500) }
      },
      O3: {
        (0..108) => { period: 8 * 60 * 60, aqi: (0..50) },
        (108.0001..140) => { period: 8 * 60 * 60, aqi: (51..100) },
        (140.0001..170) => { period: 8 * 60 * 60, aqi: (101..150) },
        (170.0001..210) => { period: 8 * 60 * 60, aqi: (151..200) },
        (210.0001..250) => { period: 8 * 60 * 60, aqi: (201..222) },
        (250.0001..328) => { period: 1 * 60 * 60, aqi: (101..150) },
        (328.0001..408) => { period: 1 * 60 * 60, aqi: (151..200) },
        (408.0001..808) => { period: 1 * 60 * 60, aqi: (201..300) },
        (808.0001..1008) => { period: 1 * 60 * 60, aqi: (301..400) },
        (1008.0001..1208) => { period: 1 * 60 * 60, aqi: (401..500) }
      },
      SO2: {
        (0..91.7) => { period: 1 * 60 * 60, aqi: (0..50) },
        (91.7001..196.5) => { period: 1 * 60 * 60, aqi: (51..100) },
        (196.5001..484.7) => { period: 1 * 60 * 60, aqi: (101..150) },
        (484.7001..796.48) => { period: 1 * 60 * 60, aqi: (151..200) },
        (796.4801..1582.48) => { period: 24 * 60 * 60, aqi: (201..300) },
        (1582.4801..2106.48) => { period: 24 * 60 * 60, aqi: (301..400) },
        (2106.4801..2630.48) => { period: 24 * 60 * 60, aqi: (401..500) }
      }
    }

    def perform
      cities.each do |city_name, ids|
        data = {}
        global_aqi = 0
        METRICS.keys.each { |metric| data[metric.to_s] = [] }

        ids.each do |id|
          result = Oj.load(::Faraday.get("http://api.gios.gov.pl/pjp-api/rest/station/sensors/#{id}").body)

          result.each do |item|
            metric = item['param']['paramCode'].gsub(/[^A-Z0-9]/, '').to_sym
            next unless METRICS.keys.include?(metric)
            sensor_result = Oj.load(::Faraday.get("http://api.gios.gov.pl/pjp-api/rest/data/getData/#{item['id']}").body)
            periods = EPA_BREAKPOINTS[metric].map { |_, v| v[:period] }.uniq
            values = periods.map do |period|
              res = sensor_result['values'].select { |val| val['date'] > (Time.now - period).to_s }
                                           .map { |item| item['value'] }.compact
              res = sensor_result['values'].select { |val| val['date'] > (Time.now - period - 3600).to_s }
                                           .map { |item| item['value'] }.compact if res.empty?
              res
            end.detect { |v| !v.empty? }
            value = values.sum / values.size.to_f
            value_range, aqi_range = EPA_BREAKPOINTS[metric].detect { |val_range, _| val_range.include?(value) }.yield_self { |x| [x[0], x[1][:aqi]] }

            aqi = (aqi_range.last.to_f - aqi_range.first.to_f) / (value_range.last.to_f - value_range.first.to_f) * (value - value_range.first) + aqi_range.first

            data[item['param']['paramCode'].gsub(/[^A-Z0-9]/, '')].push(aqi)
          end
        end

        data.each do |metric, values|
          next if metric == 'AQI'
          aqi = values.sum / values.size.to_f
          global_aqi = [global_aqi, aqi].max
          gauges[metric.to_sym].set(aqi, labels: { city: city_name }) unless values.empty?
        end

        gauges[:AQI].set(global_aqi, labels: { city: city_name })
      end
    end

    def self.interval
      '30m'
    end

    private

    def gauges
      return @gauges if defined?(@gauges)

      @gauges = {
        aqi: Prometheus::Client::Gauge.new(:apigios_aqi, docstring: 'Air quality index (GIOS)', labels: [:city])
      }

      METRICS.each do |metric, desc|
        @gauges[metric] = Prometheus::Client::Gauge.new(:"aqigios_#{metric.downcase}", docstring: desc, labels: [:city])
      end

      @gauges
    end

    def cities
      @cities ||= Hash[
        ENV.fetch('TASK_APIGIOS_CITIES').split(';').map { |city| name, ids = city.split(':'); [name, ids.split(',')] }
      ]
    end
  end
end

