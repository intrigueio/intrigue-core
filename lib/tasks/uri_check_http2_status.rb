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

  def check_h2_sync(uri_param)

    # require enrichment
    require_enrichment
    draft = 'h2'

    # return data
    res_code = nil
    res_headers = nil

    uri = URI.parse(uri_param)
    tcp = TCPSocket.new(uri.host, uri.port)
    sock = nil

    if uri.scheme == 'https'
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE

      # For ALPN support, Ruby >= 2.3 and OpenSSL >= 1.0.2 are required

      ctx.alpn_protocols = [draft]
      ctx.alpn_select_cb = lambda do |protocols|
        # puts "ALPN protocols supported by server: #{protocols}"
        draft if protocols.include? draft
      end

      sock = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
      sock.sync_close = true
      sock.hostname = uri.hostname
      sock.connect

      if sock.alpn_protocol != draft
        # puts "Failed to negotiate #{draft} via ALPN"
        return [nil, nil, nil]
      end
    else
      sock = tcp
    end

    conn = HTTP2::Client.new
    stream = conn.new_stream

    conn.on(:frame) do |bytes|
      # puts "Sending bytes: #{bytes.unpack("H*").first}"
      sock.print bytes
      sock.flush
    end
    conn.on(:frame_sent) do |frame|
      # puts "Sent frame: #{frame.inspect}"
    end
    conn.on(:frame_received) do |frame|
      # puts "Received frame: #{frame.inspect}"
    end

    conn.on(:promise) do |promise|
      promise.on(:promise_headers) do |h|
        # _log "promise request headers: #{h}"
      end

      promise.on(:headers) do |h|
        # _log "promise headers: #{h}"
      end

      promise.on(:data) do |d|
        # _log "promise data chunk: <<#{d.size}>>"
      end
    end

    conn.on(:altsvc) do |f|
      # _log "received ALTSVC #{f}"
    end

    stream.on(:close) do
      # _log 'stream closed'
    end

    stream.on(:half_close) do
      # _log 'closing client-end of the stream'
    end

    stream.on(:headers) do |h|
      # _log "response headers: #{h}"
      res_headers = h
      h.each do |hh|
        if hh[0] == ":status"
          res_code = hh[1]
          _log "Received response code: #{code}"
        end
      end
    end

    stream.on(:data) do |d|
      # _log "response data chunk: <<#{d}>>"
    end

    stream.on(:altsvc) do |f|
      # _log "received ALTSVC #{f}"
    end

    head = {
      ':scheme' => uri.scheme,
      ':method' => 'GET',
      ':authority' => [uri.host, uri.port].join(':'),
      ':path' => uri.path,
      'accept' => '*/*'
    }

    _log 'Sending HTTP 2.0 GET request'
    stream.headers(head, end_stream: true)
    while !sock.closed? && !sock.eof?
      data = sock.read_nonblock(1024)
      # puts "Received bytes: #{data.unpack("H*").first}"

      begin
        conn << data
      rescue StandardError => e
        # puts "#{e.class} exception: #{e.message} - closing socket."
        e.backtrace.each { |l| puts "\t" + l }
        sock.close
      end
    end

    # just fail
    #return [nil,nil,nil] unless response

  return [true, res_code, res_headers]
  end

end
end
end
