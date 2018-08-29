require 'slack-ruby-client'

module Intrigue
module Notifier
  class Slack < Intrigue::Notifier::Base

    def self.metadata
      { :type => "slack" }
    end

    def initialize(config_hash)
      puts "Creating new slack notifier with config: #{config_hash}"
      @system_base_uri = config_hash["system_base_uri"]
      @access_key = config_hash["access_key"]
      @bot_name = config_hash["bot_name"]
      @channel_name = config_hash["channel_name"]
    end

    def notify(message, result)

      result_url = "#{@system_base_uri}/#{result.project.name}/results/#{result.id}"

      ::Slack.configure do |config|
        config.token = @access_key
      end

      client = ::Slack::Web::Client.new
      client.chat_postMessage(
        text: "#{message}\nMore details at: #{result_url}",
        as_user: false,
        username: @bot_name,
        channel: @channel_name
      )

    end
  end

end
end
