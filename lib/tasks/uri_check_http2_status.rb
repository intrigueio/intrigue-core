module Intrigue
module Task
class UriCheckHttp2Support < BaseTask

  def self.metadata
    {
      :name => "uri_check_http2_support",
      :pretty_name => "URI Check HTTP/2 Support",
      :authors => ["jcran"],
      :description =>   "This task checks for ",
      :references => [ "https://github.com/ostinelli/net-http2" ],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        { 
          "type" => "Uri", 
          "details" => {"name" => "http://www.intrigue.io"} 
        }
      ],
      :allowed_options => [
         {:name => "connect_timeout", regex: "integer", :default => 10 },
      ],
      :created_types => []
    }
  end

  def run

    # Check Synchronous request / response  
    valid, code, headers = check_h2_sync(_get_entity_name)
    if valid
      _log "Response?: #{valid}"
      _log "Response Code: #{code}"
      _log "Response Headers: #{headers}"
      _set_entity_detail "http2", true
    else 
      _log_error "Unsupported!"
      _set_entity_detail "http2", false
    end

  end #end run

  def check_h2_sync(uri)

      # create a client
      timeout = _get_option("connect_timeout")
      
      client = ::NetHttp2::Client.new(uri, connect_timeout: timeout)

      # error handling 
      client.on :error do |e|
       _log "Client encountered an error:"
       _log e
      end

      # send request
      response = client.call(:get, '/')

      # close the connection
      client.close
   
      # just fail
      return [nil,nil,nil] unless response

  [response.ok?, response, response.headers]
  end 

end
end
end
