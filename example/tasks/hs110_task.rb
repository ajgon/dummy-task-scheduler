require 'socket'

module Tasks
  class HS110Task < ApplicationTask
    KEY = 171.freeze
    PORT = 9999.freeze
    METRICS = {
      voltage_mv: 'Current Voltage in mV',
      current_ma: 'Current Amperage in mA',
      power_mw: 'Current power in mW',
      total_wh: 'Total power consumption in Wh'
    }

    def perform
      ips.each do |ip|
        data = fetch(ip, emeter: { get_realtime: {} })
        METRICS.each do |metric, _|
          metric_data = data['emeter']['get_realtime'][metric.to_s]
          gauges[metric].set(metric_data.to_f, labels: { ip: ip }) if metric_data
        end
      end
    end

    def self.interval
      '10s'
    end

    private

    def gauges
      return @gauges if defined?(@gauges)

      @gauges = {}

      METRICS.each do |metric, desc|
        @gauges[metric] = Prometheus::Client::Gauge.new(:"hs110_#{metric}", docstring: desc, labels: [:ip])
      end

      @gauges
    end

    def fetch(ip, request)
      socket = Socket.tcp(ip, PORT, connect_timeout: 5)
      socket.write(encrypt(Oj.dump(request, mode: :compat)))
      result = socket.recvfrom(2048)
      socket.close

      Oj.load(decrypt(result[0][4..-1]))
    end

    def encrypt(value)
      key = KEY
      result = [value.size].pack('>I').reverse

      value.split('').each do |char|
        key ^= char.ord
        result += key.chr
      end

      result
    end

    def decrypt(value)
      key = KEY
      result = ''

      value.split('').each do |char|
        tmp = key ^ char.ord
        key = char.ord
        result += tmp.chr
      end

      result
    end

    def ips
      @ips ||= ENV.fetch('TASK_HS110_IPS').split(',')
    end
  end
end
