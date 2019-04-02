require 'slack-ruby-client'

module Intrigue
module Notifier
  class Slack < Intrigue::Notifier::Base

    include Intrigue::Task::Web

    def self.metadata
      { :type => "slack" }
    end

    def initialize(config_hash)
      #puts "Creating new slack notifier with config: #{config_hash}"

      # Assumes amazon...
      if config_hash["system_base_uri"] == "AMAZON"
        # use the standard endpoint to grab info 
        system_ip = http_get_body("http://169.254.169.254/latest/meta-data/public-ipv4")
        @system_base_uri = "http://#{system_ip}:7777"
      else # use as is
        @system_base_uri = config_hash["system_base_uri"]
      end

      @access_key = config_hash["access_key"]
      @bot_name = config_hash["bot_name"]
      @channel_name = config_hash["channel_name"]
    end

    def notify(message, result=nil)

      result_url = "#{@system_base_uri}"
      result_url += "/#{result.project.name}/results/#{result.id}" if result

      constructed_message = "#{message}\nMore details at: ```#{result_url}```"

      ::Slack.configure do |config|
        config.token = @access_key
      end

      begin
        client = ::Slack::Web::Client.new
        client.chat_postMessage(
          text: constructed_message,
          as_user: false,
          username: @bot_name,
          channel: @channel_name
        )
      rescue Errno::EADDRNOTAVAIL => e
        # fail silently? :(
      rescue ::Slack::Web::Api::Errors::TooManyRequestsError => e
        # fail silently? :(
      rescue Faraday::ConnectionFailed => e
        # fail silently? :(
      end

    end
  end

end
end
