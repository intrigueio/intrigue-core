module Intrigue
module Task
class UriCheckSecurityHeaders < BaseTask

  def self.metadata
    {
      :name => "uri_check_security_headers",
      :pretty_name => "URI Check Security Headers",
      :authors => ["jcran"],
      :description =>   "This task checks for compliance with a security policy, including security headers",
      :references => [
        "https://securityheaders.com"
      ],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        { 
          "type" => "Uri", 
          "details" => {"name" => "http://www.intrigue.io"} 
        }
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  def run
    super

    uri = _get_entity_name
    response = http_request(:get, uri)
    
    # return immediately unless we got a response 
    return nil unless response 

    # other things to check: (?)
    # form available over HTTP
    # set cookie over http 
    # server header

    # security headers 
    required_headers = [ 
      "content-security-policy",
      "strict-transport-security", 
      "x-frame-options",
      "x-xss-protection", 
      "x-content-type-options", 
      "feature-policy", 
      "x-content-type-options"
    ]

    # TODO - check for optional headers ?
    #optional_security_headers = [
    #  "expect-ct"
    #]

    found_headers = []

    # iterate through and find the ones we have
    response.each_header do |name,value|
      found_headers << name if required_headers.include? name
    end # end each_header

    # If we have identified any headers...
    if found_headers.count != required_headers.count
      missing_headers = required_headers - found_headers
      # report the headers that are missing 
      _create_issue({
        name: "Missing security headers",
        type: "missing_security_headers",
        severity: 5,
        status: "confirmed",
        description:  "One or more security headers was missing from #{uri}. " +
                      "You can learn more about security headers at " + 
                      "https://www.keycdn.com/blog/http-security-headers",
        details: {
          uri: uri,
          missing:  missing_headers
        }
      })
    end

  end #end run

end
end
end
