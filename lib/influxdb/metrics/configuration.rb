require 'influxdb/metrics/controller'
require 'influxdb/metrics/model'

module InfluxDB
  module Metrics
    class Configuration
      EVENTS = {
        action_controller: Controller,
        active_record: Model
      }

      attr_accessor :hosts
      attr_accessor :username
      attr_accessor :password
      attr_accessor :database
      attr_accessor :app_name
      attr_accessor :port
      attr_accessor :debug
      attr_accessor :async

      attr_writer :client

      attr_reader :logger
      attr_reader :events
      attr_reader :subscribed

      def initialize
        @hosts      = []
        @app_name   = 'rails'
        @username   = 'root'
        @password   = 'root'
        @database   = 'rails'
        @port       = 8086
        @async      = true
        @debug      = false
        @events     = EVENTS.values
        @subscribed = []
      end

      def host=(value)
        hosts << value
      end

      # Configure specific subscriptions
      def events=(names)
        @events = [*names].map do |name|
          EVENTS.fetch(name)
        end
      end

      def subscribe
        @subscribed = events.map do |event|
          event.new.tap(&:subscribe)
        end
      end

      def write_point(name, data = {})
        http = Net::HTTP.new(@hosts[0], @port)
        url = "/write?consistency=all&db=#{@database}&precision=s&rp="
        
        tags = {"action" => data.delete(:action), "format" => data.delete(:format), "status" => data.delete(:status)}
        tags = tags.keys.map{|k| "#{k}=#{tags[k]}" }.join(",")
        
        fields = data.keys.map{|k| "#{k}=#{data[k].is_a?(String) ? data[k].inspect : data[k]}" }.join(",")
        line = "#{name},#{line_escape(tags)} #{line_escape(fields)}"

        request = Net::HTTP::Post.new(url, { "Content-Type" => "application/octet-stream" })
        request.body = line
        response = http.request(request)
      end
      
      def line_escape(string)
        string.gsub(" ", "\ ").gsub("=", "\=").gsub(",", "\,")
      end

      def logger=(value)
        InfluxDB::Logging.logger = value if debug
        @logger = value
      end
    end
  end
end
