module Intrigue
module Task
class UriCheckApiEndpoint < BaseTask

  include Intrigue::Task::Browser

  def self.metadata
    {
      :name => "uri_check_api_endpoint",
      :pretty_name => "URI Check API Endpoint",
      :authors => ["jcran"],
      :description => "This task uses a variety of heuristics to determine if this is an api endpoint.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://www.intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types =>  []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # start with negative
    api_endpoint = nil

    # get our url
    url = _get_entity_name


    ####
    # first just check keywords in the url 
    ####

    api_endpoint = true if url =~ /api\./
    api_endpoint = true if url =~ /\/api/
    api_endpoint = true if url =~ /\/json/
    api_endpoint = true if url =~ /\.json/
    api_endpoint = true if url =~ /\.xml/

    if api_endpoint
      # set the details
      _create_entity "ApiEndpoint", { "name" => u }
      _set_entity_detail "api_endpoint", api_endpoint # legacy (keep the attribute on the base entity)
      return # return if our base URL was an endpoint
    end

    ####
    # otherwise check patterns around the original
    ####

    # first get a standard response
    standard_response = http_request :get, url

    [ "#{url}", "#{url}/api", "#{url}/graphql" ].each do |u|

      _log "Checking... #{u}"
      api_endpoint = false 
      
      # Go ahead and get the response for this paritcular endpoint
      response = http_request :get, u

      # check for content type of application.. note that this will flag
      # application/javascript, which is probably not wanted
      headers = response.each_header.to_h
      if headers
        ct = headers.find{|x, y| x if x =~ /^content-type/i }
        if ct
          api_endpoint = true if "#{headers[ct]}" =~ /^application\/xml/i
          api_endpoint = true if "#{headers[ct]}" =~ /^application\/json/i
          api_endpoint = true if "#{headers[ct]}" =~ /^application\/ld+json/i
          api_endpoint = true if "#{headers[ct]}" =~ /^application\/x-protobuf/i
          api_endpoint = true if "#{headers[ct]}" =~ /^application\/octet-stream/i
          api_endpoint = true if "#{headers[ct]}" =~ /^text\/csv/i
        end
      end
      
      # try to parse it (JSON)
      begin
        # get request body
        body = response.body
        if body 
          json = JSON.parse(body)
          api_endpoint = true if json
        end
      rescue JSON::ParserError      
        _log "No body!"
      end

      # check known fingeprints
      _log "Attempting to fingerprint (without the browser)!"
      ident_matches = generate_http_requests_and_check(u,{:enable_browser => false, :'only-check-base-url' => true}) || {}
      ident_fingerprints = ident_matches["fingerprint"] || []
      ident_fingerprints.each do |fp|
        api_endpoint = true if fp["tags"] && fp["tags"].include?("API")
      end

      # skip if we're not the original url, but we're getting the same response
      next if u != url && body == standard_response.body

      # set the details and create a new entity if we made it this far!
      if api_endpoint
        _create_entity "ApiEndpoint", { "name" => u }
        _set_entity_detail "api_endpoint", api_endpoint # legacy (keep the attribute on the base entity)
      end
    
    end

  end

end
end
end
