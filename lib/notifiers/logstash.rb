require 'logstash-logger'

module Intrigue
module Notifier
  class Logstash < Intrigue::Notifier::Base

    def self.metadata
      { :type => "logstash" }
    end

    def initialize(config_hash)

      config_hash = {}

      @host = config_hash["host"] ||  "localhost"
      @port = config_hash["port"] ||  5000

      # configure
      config = LogStashLogger.configure do |config|
       config.customize_event do |event|
         event["token"] = @token
       end
      end

      @logger = logger = LogStashLogger.new(type: :tcp, host:"#{@token}", port: @port)

    end

    def notify(message, result=nil)
      result_url = "/#{result.project.name}/results/#{result.id}" if result
      constructed_message = "#{message}\nMore details at: #{result_url}"
      @logger.info constructed_message
    end

  end

end
end
