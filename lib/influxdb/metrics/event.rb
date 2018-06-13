require 'active_support/notifications'

module InfluxDB
  module Metrics
    class Event
      def subscribe
        ActiveSupport::Notifications.subscribe(subscribe_to) do |*args|
          handle(*args)
        end
      end

      def subscribe_to
        fail NotImplementedError, 'Must implement #subscribe_to'
      end

      def handle(name, id, start, finish, payload)
        fail NotImplementedError, 'Must implment #handle'
      end

      private

      delegate :config, to: InfluxDB::Metrics
      delegate :write_point, :logger, to: :config

      def log(level, message)
        logger.send(level, '[InfluxDB::Metrics] ' + message) if logger
      end

      def duration(start, finish)
        ((finish - start) * 1000).ceil
      end
    end
  end
end
