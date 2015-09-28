module Intrigue
module Handler
  class Webhook < Intrigue::Handler::Base

    def self.type
      "webhook"
    end

    def process(task_result, options)
      uri = options[:hook_uri]
      begin
        recoded_string = task_result.export_json.encode('UTF-8', :invalid => :replace, :replace => '?')
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
