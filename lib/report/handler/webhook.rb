module Intrigue
module Report
module Handler
  class Webhook < Intrigue::Report::Handler::Base

    def self.type
      "webhook" # XXX can we get this from self.class?
    end

    def generate(task_result, options)
      uri = options[:hook_uri]
      begin
        recoded_string = task_result.to_json.encode('UTF-8', :invalid => :replace, :replace => '?')
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
end
