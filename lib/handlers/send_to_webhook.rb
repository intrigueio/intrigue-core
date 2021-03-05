module Intrigue
module Core
module Handler
  class SendToWebhook < Intrigue::Core::Handler::Base

    def self.metadata
      {
        :name => "send_to_webhook",
        :pretty_name => "Send To Webhook",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      return "Unable to process" unless result.respond_to? "export_json"

      begin
        uri = _get_handler_config "uri"
        puts "handler called for #{result.name}, sending to #{uri}"
        RestClient.post uri, result.export_json, :content_type => "application/json"
      rescue Encoding::UndefinedConversionError  => e
        puts "ERROR! Bad encoding in data: #{e}"
        return false
      rescue JSON::GeneratorError => e
        puts "ERROR! Unable to generate JSON: #{e}"
        return false
      rescue Errno::EPIPE => e
        puts "ERROR! Unable to connect: #{e}"
        return false
      rescue Errno::ECONNREFUSED => e
        puts "ERROR! Unable to connect: #{e}"
        return false
      rescue RestClient::ResourceNotFound => e
        puts "ERROR! Unable to locate endpoint: #{e}"
        return false
      rescue RestClient::ServerBrokeConnection => e
        puts "ERROR! Endpoint unable to accept data: #{e}"
        return false
      rescue RestClient::NotImplemented => e
        puts "ERROR! Endpoint unable to accept data: #{e}"
        return false
      end
    true
    end

  end
end
end
end