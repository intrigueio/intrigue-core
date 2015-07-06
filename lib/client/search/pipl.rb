module Client
module Search
module Pipl

  class ApiClient
    include Task::Web

    attr_accessor :service_name

    def initialize(key)
      @api_key = key
    end

    def search(type, string)

      # Convert to a get-paramenter
      #string = CGI.escapeHTML string.strip
      #string.gsub!(" ", "%20")

      uri = _get_uri(type,string)

      begin
        response = http_get_body(uri)
        JSON.parse(response) if response
      rescue URI::InvalidURIError
        return response['error'] => "Error using search uri: #{search_uri}"
      rescue JSON::ParserError
        return response['error'] => "Invalid JSON returned: #{response}"
      end
    end

    private

    def _get_uri(type, string)
      if type == :email
        "http://api.pipl.com/search/v3/json/?email=#{string}&exact_name=0&query_params_mode=and&key=#{@api_key}"
      elsif type == :phone
        "http://api.pipl.com/search/v3/json/?phone=#{string}&exact_name=0&query_params_mode=and&key=#{@api_key}"
      elsif type == :username
        "http://api.pipl.com/search/v3/json/?username=#{string}&exact_name=0&query_params_mode=and&key=#{@api_key}"
      else
        raise "Unknown search type"
      end
    end

  end

end
end
end
