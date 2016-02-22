module Intrigue
module Handler
  class WebhookGeneric < Intrigue::Handler::Base

    def self.type
      "webhook_generic"
    end

    def process(result)
      uri = _get_handler_config "uri"
      begin
        recoded_string = result.export_json.encode('UTF-8', :invalid => :replace, :replace => '?')
        RestClient.post uri, recoded_string, :content_type => "application/json"
      rescue Encoding::UndefinedConversionError
        return false
      rescue JSON::GeneratorError
        return false
      end
    end

  end
end
end
