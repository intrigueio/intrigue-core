require 'open-uri'
require 'cgi'

module Intrigue
module Client
module Search
module Pipl

  class ApiClient
    include Intrigue::Task::Web

    def initialize(key)
      @api_key = key
    end

    def search(type, string)

      uri = _get_uri(type,string)

      begin
        response = open(uri)
        JSON.parse(response.read) if response
      rescue URI::InvalidURIError
        return nil
      rescue JSON::ParserError
        return nil
      end
    end

    private

    def _get_uri(type, string)

      sanitized_string = string.gsub(" ","")

      if type == :email
        uri= "http://api.pipl.com/search/v4/?email=#{sanitized_string}&key=#{@api_key}"
      elsif type == :phone
        uri= "http://api.pipl.com/search/v4/?phone=#{sanitized_string}&key=#{@api_key}"
      else
        uri= "http://api.pipl.com/search/v4/?username=#{sanitized_string}&key=#{@api_key}"
      end

      puts "PIPL URI: #{uri}"

    return uri
    end

  end

end
end
end
end