require 'slack-ruby-client'

module Intrigue
module Handler
  class Slackbot < Intrigue::Handler::Base

    def self.type
      "slackbot"
    end

    def perform(result_type, result_id, prefix_name=nil)

      puts "Called on: #{result_type}##{result_id}"

      result = eval(result_type).first(id: result_id)
      return "Unable to process" unless result.respond_to? "export_hash"

      Slack.configure do |config|
        config.token = _get_handler_config("access_key")
      end

      system_base_uri = "#{_get_handler_config("system_base_uri")}"
      bot_name = _get_handler_config("bot_name")
      channel_name = _get_handler_config("channel_name")
      result_url = "#{system_base_uri}/#{result.project.name}/results/#{result_id}"
      entities_uri = "#{system_base_uri}/#{result.project.name}/entities"

      client = Slack::Web::Client.new
      result.entities.each do |e|
        client.chat_postMessage( text: "#{entities_uri}/#{e.id} [#{e.name}]",
          as_user: false,
          username: bot_name,
          channel: channel_name
        )
      end

    end
  end
end
end
