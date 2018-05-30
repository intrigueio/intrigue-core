require 'slack-ruby-client'

module Intrigue
module Handler
  class SlackbotBuckets < Intrigue::Handler::Base

    def self.metadata
      {
        :name => "slackbot_buckets",
        :type => "notify"
      }
    end

    def self.type
      "slackbot_buckets"
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      return "Unable to process" unless result.respond_to? "export_hash"

      Slack.configure do |config|
        config.token = _get_handler_config("access_key")
      end

      system_base_uri = "#{_get_handler_config("system_base_uri")}"
      bot_name = _get_handler_config("bot_name")
      channel_name = _get_handler_config("channel_name")
      result_url = "#{system_base_uri}/#{result.project.name}/results/#{result_id}"

      client = Slack::Web::Client.new

      # Note that this is currently called by an enrichment task, which makes it
      # a little more funky than your typical notification. we have to go get
      # the base entity of the task result...
      message = "#{result.base_entity.get_detail("interesting_files")}"

      client.chat_postMessage(
        text: "#{message}\nMore details at: #{result_url}",
        as_user: false,
        username: bot_name,
        channel: channel_name
      )

    end
  end

end
end
