require 'webrick'
require 'socket'

module Intrigue
module Task
module Server

module Listeners

  def start_tcp_listener(port)
    Thread.new do
      begin
        server = TCPServer.new port
        # add ssl cert for typical ssl ports here
        # https://stackoverflow.com/questions/5872843/trying-to-create-a-simple-ruby-server-over-ssl
        loop do
          c = server.accept    # Wait for a client to connect
          yield c
        end
      rescue SocketError => e
        _log_error "Unable to bind: #{e}"
      rescue Errno::EADDRINUSE => e
        _log_error "Unable to bind: #{e}"
      rescue Errno::EMFILE => e
        _log_error "Unable to bind: #{e}"
      rescue Errno::EACCES => e
        _log_error "Unable to bind: #{e}"
      end
    end
  end

  def start_ssl_listener(port)

    cert = Intrigue::Task::SelfSignedCertificate.new
    cert_output = cert.generate
    begin
      server = TCPServer.new(port)
      sslContext = OpenSSL::SSL::SSLContext.new
      sslContext.cert = OpenSSL::X509::Certificate.new(cert_output["cert"])
      sslContext.key = OpenSSL::PKey::RSA.new(cert_output["key"])
      sslServer = OpenSSL::SSL::SSLServer.new(server, sslContext)

      loop do
        c = sslServer.accept
        Thread.new do
          begin
            yield c
          rescue OpenSSL::SSL::SSLError => e
            _log_error "Invalid handshake: #{e}"
          end
        end
      end
    rescue SocketError => e
      _log_error "Unable to bind: #{e}"
    rescue Errno::EADDRINUSE => e
      _log_error "Unable to bind: #{e}"
    rescue Errno::EMFILE => e
      _log_error "Unable to bind: #{e}"
    rescue Errno::EACCES => e
      _log_error "Unable to bind: #{e}"
    end
  end

end

class SsrfResponder

  include Sidekiq::Worker
  sidekiq_options :queue => "app", :backtrace => true

  def self.start_and_background(port=55555)
    self.perform_async port
  end

  def perform(port)
    begin
      @server = ::WEBrick::HTTPServer.new(:Port => port)
      @server.mount "/", SsrfResponderServerBehavior
      @server.start
    rescue Errno::EADDRINUSE => e
      # just return if it's already running
    end
  end

end

class SsrfResponderServerBehavior < ::WEBrick::HTTPServlet::AbstractServlet
  def do_GET(request, response)

    #
    # this request can come with a specific id,
    # which we should be able to to correlate
    #
    task_result_id = request.query["int_id"]
    parameter = request.query["int_param"]
    t = Intrigue::Model::TaskResult.first(:id => task_result_id )
    t.log_good "VULNERABLE! #{parameter}"
    #t.log_good "REQUEST: #{request.inspect}"

    # save it on the entity
    e = t.base_entity
    ssrf_params = e.get_detail("ssrf_params") || []
    ssrf_params << parameter
    e.set_detail "ssrf_params", ssrf_params

    response.status = 200
  request.body
  end

  def do_POST(request, response)

    #
    # this request can come with a specific id,
    # which we should be able to to correlate
    #
    task_result_id = request.query["int_id"]
    parameter = request.query["int_param"]
    t = Intrigue::Model::TaskResult.first(:id => task_result_id )
    t.log_good "VULNERABLE! #{parameter}"
    #t.log_good "REQUEST: #{request.inpect}"

    # save it on the entity
    e = t.base_entity
    ssrf_params = e.get_detail("ssrf_params") || []
    ssrf_params << parameter
    e.set_detail "ssrf_params", ssrf_params

    response.status = 200
  request.body
  end
end

end
end
end
