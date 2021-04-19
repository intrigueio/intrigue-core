module Intrigue
module Task
class UriCheckHttp2Support < BaseTask

  def self.metadata
    {
      :name => "uri_check_http2_support",
      :pretty_name => "URI Check HTTP/2 Support",
      :authors => ["jcran", "shpendk"],
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
    mytimeout = _get_option "connect_timeout"
    # Check Synchronous request / response
    valid, code, headers = check_h2_sync(_get_entity_name, mytimeout)
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

  def check_h2_sync(uri_param, mytimeout)

    # require enrichment TODO UNCOMMENT ME
    draft = 'h2'

    # return data
    res_code = nil
    res_headers = nil

    uri = URI.parse(uri_param)
    # Use Socket instead of TCPSocket because the former supports timeouts
    begin
      tcp = ::Socket.tcp(uri.host, uri.port, connect_timeout: mytimeout)
      sock = nil
    rescue Errno::ETIMEDOUT
      _log_error "Connection timeout!"
      return [nil,nil,nil]
    rescue Errno::ENETUNREACH
      _log_error "Network unreachable!"
      return [nil,nil,nil]
    rescue SocketError
      _log_error "Cannot resolve hostname!"
      return [nil,nil,nil]
    end

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

  return [true, res_code, res_headers]
  end

end
end
end
