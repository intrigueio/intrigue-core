require 'timeout'
module Intrigue
module Task
class UriCheckHttp2Support < BaseTask

  def self.metadata
    {
      :name => "uri_check_http2_support",
      :pretty_name => "URI Check HTTP/2 Support",
      :authors => ["jcran"],
      :description =>   "This task checks for http2 protocol support",
      :references => [ "https://github.com/ostinelli/net-http2" ],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        { "type" => "Uri", "details" => {"name" => "http://www.intrigue.io"} }
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

    require_enrichment

    if _get_entity_detail("code") == "0"
      _log_error "unable to proceed, connection reset"
      return
    end



    begin

      # create a client
      timeout = "#{_get_option("connect_timeout")}".to_i

      client = ::NetHttp2::Client.new(uri, connect_timeout: timeout)

      error = false
      # error handling
      client.on :error do |e|
        _log_error "Client encountered an error:"
        _log_error e
        error = true
      end

      # send request
      response = client.call(:get, _get_entity_name)
      return unless response
      return if error

      # read the response
      response.ok?      # => true
      response.status   # => '200'
      response.headers  # => {":status"=>"200"}
      response.body     # => "A body"


      # close the connection
      client.close

    rescue TypeError => e  # IS there a better way to do this?
      _log_error "Unable to connect"
    rescue OpenSSL::SSL::SSLError => e
      _log_error "Unable to connect, ssl error"
    rescue Errno::EPIPE => e
      _log_error "Unable to connect, broken pipe"
    rescue Errno::EHOSTUNREACH => e
      _log_error "Unable to connect, host unreachable"
    rescue Errno::ECONNREFUSED => e
      _log_error "Unable to connect, connection refused"
    rescue Errno::ECONNRESET => e
      _log_error "Unable to connect, connection reset"
    rescue Errno::ETIMEDOUT => e
      _log_error "Unable to connect, timed out"
    rescue SocketError => e
      _log_error "Unable to connect, socket error"
    end

    # just fail
    return [nil,nil,nil] unless response

  [response.ok?, response, response.headers]
  end

end
end
end
