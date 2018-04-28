module Intrigue
module Handler
  class Webhook < Intrigue::Handler::Base

    def self.type
      "webhook"
    end

    def process(result,name=nil)
      # NOTE - name is not used
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
