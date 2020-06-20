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
      :example_entities => [{"type" => "Uri", "details" => {"name" => "http://www.intrigue.io"}}],
      :allowed_options => [],
      :created_types =>  []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    require_enrichment

    # start with negative
    api_endpoint = nil

    # get our url
    url = _get_entity_name

    # check keywords in the url 
    api_endpoint = true if url =~ /api\./
    api_endpoint = true if url =~ /\/api/
    api_endpoint = true if url =~ /\/json/
    api_endpoint = true if url =~ /\.json/
    api_endpoint = true if url =~ /\.xml/

    # check for content type of application.. note that this will flag
    # application/javascript, which is probably not wanted
    headers = _get_entity_detail("headers") || []
    if headers
      content_type_header = headers.select{|x| x =~ /content-type/i }
      api_endpoint = true if "#{content_type_header}" =~ /^application\/xml/i
      api_endpoint = true if "#{content_type_header}" =~ /^application\/json/i
      api_endpoint = true if "#{content_type_header}" =~ /^text\/csv/i
    end
    
    # check fingerprints!
    fingerprint = _get_entity_detail("fingerprint") || []
    fingerprint.each do |fp|
      api_endpoint = true if fp["tags"] && fp["tags"].include?("API")
    end 

    # try to parse it 
    begin
      # get request body
      body = _get_entity_detail("extended_response_body")
      if body 
        json = JSON.parse(body)
        api_endpoint = true if json
      end
    rescue JSON::ParserError      
      _log "No body"
    end

    # set the details 
    _set_entity_detail "api_endpoint", api_endpoint

  end

end
end
end
