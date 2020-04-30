require 'digest'

###
### Please note - these methods may be used inside task modules, or inside libraries within
### Intrigue. An attempt has been made to make them abstract enough to use anywhere inside the
### application, but they are primarily designed as helpers for tasks. This is why you'll see
### references to @task_result in these methods. We do need to check to make sure it's available before
### writing to it.
###

# This module exists for common web functionality
module Intrigue
module Task
  module Web

  def make_http_requests_from_queue(uri, work_q, threads=1, create_url=false, create_issue=false)

    ###
    ### Get the default case (a page that doesn't exist)
    ###
    threads = threads.to_i # jsut in case
    random_value = "#{rand(100000000)}"
    request_page_one = "doesntexist-#{random_value}"
    request_page_two = "def-#{random_value}-doesntexist"
    response = http_request :get,"#{uri}/#{request_page_one}"
    response_two = http_request :get,"#{uri}/#{request_page_two}"

    # check for sanity
    unless response && response_two
      _log_error "Unable to connect to site!"
      return false
    end

    # check to make sure we don't just go down the rabbit hole
    # some pages print back our uri, so first remove that if it exists
    unless response.body.gsub(request_page_one,"") && response_two.body.gsub(request_page_two,"")
      _log_error "Cowardly refusing to test - different responses on our missing page checks"
      return false
    end

    # Default to code
    missing_page_test = :code
    # But select based on the response to our random page check
    case response.code
      when "404"
        _log "Using CODE as missing page test, missing page will give a 404"
        missing_page_test = :code
      when "200"
        _log "Using CONTENT as missing page test, missing page will give a 200"
        missing_page_test = :content
        missing_page_content = response.body
      else
        _log "Defaulting to CODE as missing page test, missing page will give a #{response.code}"
        missing_page_test = :code
        missing_page_code = response.code
    end
    ##########################

    matching_urls = Queue.new

    # Create a pool of worker threads to work on the queue
    workers = (0...threads).map do
      Thread.new do
        begin
          while request_details = work_q.pop(true)

            request_uri = "#{uri}#{request_details[:path]}"

            # Do the check
            #_log "Checking #{request_uri}"

            # request details will have regexes if we want to check, so just pass it directly
            result = check_uri_exists(request_uri, missing_page_test, missing_page_code, missing_page_content, request_details)

            if result
              # create a new entity for each one if we specified that
              _create_entity("Uri", { "name" => result[:uri] }) if create_url

              # dump it into our queue so we can push matches back
              matching_urls.push({ start: request_uri, final: result[:uri] })

              # Create a linked issue if the type exists
              if _linkable_issue_exists "#{request_details[:issue_type]}"
                _log "Creating  linked issue of type: #{request_details[:issue_type]}"
                _create_linked_issue(request_details[:issue_type], result.except!(:name)) 
              else
                # Generic fallback 
                _log "Creating issue of type: #{request_details[:issue_type]}"
                _create_issue({
                  name: "Discovered Sensitive Content at #{request_details[:path]}",
                  type:  request_details[:issue_type] || "discovered_sensitive_content",
                  severity: request_details[:severity] || 5,
                  status: request_details[:status] || "potential",
                  description: "Page was found at #{result[:name]} with a code #{result[:response_code]} by url_brute_focused_content.",
                  details: result.except!(:name)
                }) if create_issue
              end
            end

          end # end while
        rescue ThreadError
        end
      end
    end; "ok"
    workers.map(&:join); "ok"

    # push back a list of matching urls in case of post processing
    matching_urls.size.times.map {|x| matching_urls.pop }
  end

  # See: https://raw.githubusercontent.com/zendesk/ruby-kafka/master/lib/kafka/ssl_socket_with_timeout.rb
  def connect_ssl_socket(hostname, port, timeout=15, max_attempts=3)
    # Create a socket and connect
    # https://apidock.com/ruby/Net/HTTP/connect
    attempts=0

    begin

      # keep track of how many times we've tried
      attempts +=1

      ssl_context = OpenSSL::SSL::SSLContext.new
      #ssl_context.min_version = OpenSSL::SSL::SSL2_VERSION
      #ssl_context.ssl_version = :SSLv23

      # possible min versions:
      # OpenSSL::SSL::SSL2_VERSION
      # OpenSSL::SSL::SSL3_VERSION
      # OpenSSL::SSL::TLS1_1_VERSION
      # OpenSSL::SSL::TLS1_2_VERSION
      # OpenSSL::SSL::TLS1_VERSION

      # Open a tcp socket
      addr = Socket.getaddrinfo(hostname, nil)
      sockaddr = Socket.pack_sockaddr_in(port, addr[0][3])

      tcp_socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)
      tcp_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

      # first initiate the TCP socket
      begin
        # Initiate the socket connection in the background. If it doesn't fail
        # immediately it will raise an IO::WaitWritable (Errno::EINPROGRESS)
        # indicating the connection is in progress.
          tcp_socket.connect_nonblock(sockaddr)
      rescue IO::WaitWritable
        # select will block until the socket is writable or the timeout
        # is exceeded, whichever comes first.
        unless _select_with_timeout(tcp_socket, :connect_write, timeout)
          # select returns nil when the socket is not ready before timeout
          # seconds have elapsed
          tcp_socket.close
          raise Errno::ETIMEDOUT
        end

        begin
          # Verify there is now a good connection.
          tcp_socket.connect_nonblock(sockaddr)
        rescue Errno::EISCONN
          # The socket is connected, we're good!
        end

      end

      # once that's connected, we can start initiating the ssl socket
      ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
      ssl_socket.hostname = hostname # Required for SNI (cloudflare)

      begin
        # Initiate the socket connection in the background. If it doesn't fail
        # immediately it will raise an IO::WaitWritable (Errno::EINPROGRESS)
        # indicating the connection is in progress.
        # Unlike waiting for a tcp socket to connect, you can't time out ssl socket
        # connections during the connect phase properly, because IO.select only partially works.
        # Instead, you have to retry.
        ssl_socket.connect_nonblock
      rescue Errno::EAGAIN, Errno::EWOULDBLOCK, IO::WaitReadable
        if _select_with_timeout(ssl_socket, :connect_read, timeout)
          _log "retrying... attempt: #{attempts}/#{max_attempts}"
          retry unless attempts == max_attempts
        else
          ssl_socket.close
          tcp_socket.close
          raise Errno::ETIMEDOUT
        end
      rescue IO::WaitWritable
        if _select_with_timeout(ssl_socket, :connect_write, timeout)
          _log "retrying... attempt: #{attempts}/#{max_attempts}"
          retry unless attempts == max_attempts
        else
          ssl_socket.close
          tcp_socket.close
          raise Errno::ETIMEDOUT
        end
      end

    rescue OpenSSL::SSL::SSLError => e
      _log_error "Error requesting resource, skipping: #{hostname} #{port}: #{e}"
      _log "retrying... attempt: #{attempts}/#{max_attempts}"
      retry unless attempts == max_attempts
    rescue SocketError => e
      _log_error "Error requesting resource, skipping: #{hostname} #{port}: #{e}"
    rescue Errno::EINVAL => e
      _log_error "Error requesting resource, skipping: #{hostname} #{port}: #{e}"
    rescue Errno::EMFILE => e
      _log_error "Error requesting resource, skipping: #{hostname} #{port}: #{e}"
    rescue Errno::EAFNOSUPPORT => e
      _log_error "Error requesting resource, skipping: #{hostname} #{port}: #{e}"
    rescue Errno::EPIPE => e
      _log_error "Error requesting cert, skipping: #{hostname} #{port}: #{e}"
    rescue Errno::ECONNRESET => e
      _log_error "Error requesting cert, skipping: #{hostname} #{port}: #{e}"
    rescue Errno::ECONNREFUSED => e
      _log_error "Error requesting cert - refused, skipping: #{hostname} #{port}: #{e}"
      _log_error "Error requesting resource, skipping: #{hostname} #{port}"
      _log "retrying... attempt: #{attempts}/#{max_attempts}"
      retry unless attempts == max_attempts
    rescue Errno::ENETUNREACH
      # unable to connect
      _log_error "Error requesting cert, skipping: #{hostname} #{port}: #{e}"
    rescue Errno::ETIMEDOUT => e
      _log_error "Error requesting cert - timed out, timeout: #{hostname} #{port}: #{e}"
      _log_error "Error requesting resource, skipping: #{hostname} #{port}"
      _log "retrying... attempt: #{attempts}/#{max_attempts}"
      retry unless attempts == max_attempts
    rescue Errno::EHOSTUNREACH => e
      _log_error "Error requesting cert, skipping: #{hostname} #{port}: #{e}"
    ensure
      attempts +=1
    end

    # fail if we can't connect
    unless ssl_socket
      _log_error "Unable to connect!!"
      return nil
    end

  ssl_socket
  end

  def _select_with_timeout(socket, type, timeout)
    case type
    when :connect_read
      IO.select([socket], nil, nil, timeout)
    when :connect_write
      IO.select(nil, [socket], nil, timeout)
    when :read
      IO.select([socket], nil, nil, timeout)
    when :write
      IO.select(nil, [socket], nil, timeout)
    end
  end


  def connect_ssl_socket_get_cert(hostname,port,timeout=15)
    # connect
    socket = connect_ssl_socket(hostname,port,timeout)
    return nil unless socket && socket.peer_cert
    # Grab the cert
    cert = OpenSSL::X509::Certificate.new(socket.peer_cert)
    # parse the cert
    socket.sysclose
    # get the names
  cert
  end


  def parse_names_from_cert(cert, skip_hosted=true)

    # default to empty alt_names
    alt_names = []

    # Check the subjectAltName property, and if we have names, here, parse them.
    cert.extensions.each do |ext|
      if "#{ext.oid}" =~ /subjectAltName/

        alt_names = ext.value.split(",").collect do |x|
          "#{x}".gsub(/DNS:/,"").strip.gsub("*.","")
        end
        _log "Got cert's alt names: #{alt_names.inspect}"

        tlds = []

        # Iterate through, looking for trouble
        alt_names.each do |alt_name|

          # collect all top-level domains
          tlds << alt_name.split(".").last(2).join(".")

          universal_cert_domains = get_universal_cert_domains

          universal_cert_domains.each do |cert_domain|
            if (alt_name =~ /#{cert_domain}$/ )
              _log "This is a universal #{cert_domain} certificate, no entity creation"
              return
            end
          end

        end

        if skip_hosted
          # Generically try to find certs that aren't useful to us
          suspicious_count = 20
          # Check to see if we have over suspicious_count top level domains in this cert
          if tlds.uniq.count >= suspicious_count
            # and then check to make sure none of the domains are greate than a quarter
            _log "This looks suspiciously like a third party cert... over #{suspicious_count} unique TLDs: #{tlds.uniq.count}"
            _log "Total Unique Domains: #{alt_names.uniq.count}"
            _log "Bailing!"
            return
          end
        end
      end
    end

  alt_names
  end


  #
  # Download a file locally. Useful for situations where we need to parse the file
  # and also useful in situations were we need to verify content-type
  #
  def download_and_store(url, filename="#{SecureRandom.uuid}")

    # https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/Tempfile.html
    file = Tempfile.new(filename) # use an array to enforce a format

    # set to write in binary mode (kinda weird api, but hey)
    file.binmode

    @task_result.logger.log_good "Attempting to download #{url} and store in #{file.path}" if @task_result

    begin

      uri = URI.parse(url)

      opts = {}
      if uri.instance_of? URI::HTTPS
        opts[:use_ssl] = true
        opts[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
      end

      # TODO enable proxy
      http = Net::HTTP.start(uri.host, uri.port, nil, nil, opts) do |http|
        http.read_timeout = 15
        http.open_timeout = 15
        http.request_get(uri.path) do |resp|
          resp.read_body do |segment|
            file.write(segment)
          end
        end
      end

    rescue URI::InvalidURIError => e
      @task_result.logger.log_error "Invalid URI? #{e}" if @task_result
      return nil
    rescue URI::InvalidURIError => e
      #
      # XXX - This is an issue. We should catch this and ensure it's not
      # due to an underscore / other acceptable character in the URI
      # http://stackoverflow.com/questions/5208851/is-there-a-workaround-to-open-urls-containing-underscores-in-ruby
      #
      @task_result.logger.log_error "Unable to request URI: #{uri} #{e}" if @task_result
      return nil
    rescue OpenSSL::SSL::SSLError => e
      @task_result.logger.log_error "SSL connect error : #{e}" if @task_result
      return nil
    rescue Errno::ECONNREFUSED => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
      return nil
    rescue Errno::ECONNRESET => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
      return nil
    rescue Errno::ETIMEDOUT => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
      return nil
    rescue Net::HTTPBadResponse => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
      return nil
    rescue Zlib::BufError => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
      return nil
    rescue Zlib::DataError => e # "incorrect header check - may be specific to ruby 2.0"
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
      return nil
    rescue EOFError => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
      return nil
    rescue SocketError => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
      return nil
    rescue Encoding::InvalidByteSequenceError => e
      @task_result.logger.log_error "Encoding error: #{e}" if @task_result
      return nil
    rescue Encoding::UndefinedConversionError => e
      @task_result.logger.log_error "Encoding error: #{e}" if @task_result
      return nil
    rescue EOFError => e
      @task_result.logger.log_error "Unexpected end of file, consider looking at this file manually: #{url}" if @task_result
      return nil
    ensure
      file.flush
      file.close
    end

  file.path
  end

  # XXX - move this over to net-http (?)
  def http_post(uri, data, params)
    RestClient.post(uri, data, params)
  end

  #
  # Helper method to easily get an HTTP Response BODY
  #
  def http_get_body(uri, credentials=nil, headers={})
    response = http_request(:get, uri, credentials, headers)

    ### filter body
    if response
      return response.body.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
    end

  nil
  end

  ###
  ### XXX - significant updates made to zlib, determine whether to
  ### move this over to RestClient: https://github.com/ruby/ruby/commit/3cf7d1b57e3622430065f6a6ce8cbd5548d3d894
  ###
  def http_request(method, uri_string, credentials=nil, headers={},
        data=nil, attempts_limit=3, open_timeout=15, read_timeout=15)

    response = nil
    begin

      attempts=0
      max_attempts=attempts_limit
      found = false

      uri = URI.parse uri_string

      unless uri
        _log error "Unable to parse URI from: #{uri_string}"
        return
      end

      until( found || attempts >= max_attempts)
       @task_result.logger.log "Getting #{uri}, attempt #{attempts}" if @task_result
       attempts+=1

       if Intrigue::System::Config.config["http_proxy"]
         proxy_addr = Intrigue::System::Config.config["http_proxy"]["host"]
         proxy_port = Intrigue::System::Config.config["http_proxy"]["port"]
         proxy_user = Intrigue::System::Config.config["http_proxy"]["user"]
         proxy_pass = Intrigue::System::Config.config["http_proxy"]["pass"]
       end

       # set options
       opts = {}
       if uri.instance_of? URI::HTTPS
         opts[:use_ssl] = true
         opts[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
       end

       http = Net::HTTP.start(uri.host, uri.port, proxy_addr, proxy_port, opts)
       http.open_timeout = open_timeout
       http.read_timeout = read_timeout

       path = "#{uri.path}"
       path = "/" if path==""

       # add in the query parameters
       if uri.query
         path += "?#{uri.query}"
       end

       ### ALLOW DIFFERENT VERBS HERE
       if method == :get
         request = Net::HTTP::Get.new(uri)
       elsif method == :post
         # see: https://coderwall.com/p/c-mu-a/http-posts-in-ruby
         request = Net::HTTP::Post.new(uri)
         request.body = data
       elsif method == :head
         request = Net::HTTP::Head.new(uri)
       elsif method == :propfind
         request = Net::HTTP::Propfind.new(uri.request_uri)
         request.body = "Here's the body." # Set your body (data)
         request["Depth"] = "1" # Set your headers: one header per line.
       elsif method == :options
         request = Net::HTTP::Options.new(uri.request_uri)
       elsif method == :trace
         request = Net::HTTP::Trace.new(uri.request_uri)
         request.body = "intrigue"
       end
       ### END VERBS

      # set user agent unless one was provided
      unless headers["User-Agent"]
        headers["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1)" +
        " AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.131 Safari/537.36"
      end


       # set the user-specified headers
       headers.each do |k,v|
         request[k] = v
       end

       # handle credentials
       if credentials
         request.basic_auth(credentials[:username],credentials[:password])
       end

       # USE THIS TO PRINT HTTP REQUEST
=begin
       puts
       puts
       puts "===== BEGIN REQUEST ====="
       puts "Endpoint: #{request.method} #{uri}"
       puts "Headers:\n"
       request.each_header do |key, value|
        puts "\t#{key}: #{value}"
       end
       puts "POST Data:\n#{request.body}" if request.method == 'POST'
       puts "=====  END  REQUEST ====="
       puts
       puts
=end
       # END USE THIS TO PRINT HTTP REQUEST

       # get the response
       response = http.request(request)

       # USE THIS TO PRINT HTTP RESPONSE
       #puts
       #puts
       #puts "===== BEGIN RESPONSE ====="
       #puts "Endpoint: #{response.code} http://#{uri}"
       #puts "HEADERS:"
       #response.each_header{ |h| puts "#{h}: #{response[h]}"}
       #puts
       #puts "Body:\n#{response.body}"
       #puts "=====  END RESPONSE ====="
       #puts
       #puts
       # END USE THIS TO PRINT HTTP RESPONSE

       if response.code=="200"
         break
       end

       if (response.header['location']!=nil)
         newuri=URI.parse(response.header['location'])
         if(newuri.relative?)
             #@task_result.logger.log "url was relative" if @task_result
             newuri=uri+response.header['location']
         end
         uri=newuri

       else
         found=true #resp was 404, etc
       end #end if location
     end #until

    ### TODO - this code may be be called outside the context of a task,
    ###  meaning @task_result is not available to it. Below, we check to
    ###  make sure that it exists before attempting to log anything,
    ###  but there may be a cleaner way to do this (hopefully?). Maybe a
    ###  global logger or logging queue?
    ###
    #rescue TypeError
    #  # https://github.com/jaimeiniesta/metainspector/issues/125
    #  @task_result.logger.log_error "TypeError - unknown failure" if @task_result
    rescue Errno::EMFILE
    rescue ArgumentError => e
      @task_result.logger.log_error "Unable to open connection: #{e}" if @task_result
    rescue Net::OpenTimeout => e
      @task_result.logger.log_error "OpenTimeout Timeout : #{e}" if @task_result
    rescue Net::ReadTimeout => e
      @task_result.logger.log_error "ReadTimeout Timeout : #{e}" if @task_result
    rescue Errno::ETIMEDOUT => e
      @task_result.logger.log_error "ETIMEDOUT Timeout : #{e}" if @task_result
    rescue Errno::EINVAL => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    rescue Errno::EAFNOSUPPORT => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    rescue Errno::ENETUNREACH => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    rescue Errno::EHOSTUNREACH => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    rescue URI::InvalidURIError => e
      #
      # XXX - This is an issue. We should catch this and ensure it's not
      # due to an underscore / other acceptable character in the URI
      # http://stackoverflow.com/questions/5208851/is-there-a-workaround-to-open-urls-containing-underscores-in-ruby
      #
      @task_result.logger.log_error "Unable to request URI: #{uri} #{e}" if @task_result
    rescue OpenSSL::SSL::SSLError => e
      @task_result.logger.log_error "SSL connect error : #{e}" if @task_result
    rescue Errno::ECONNREFUSED => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    rescue Errno::ECONNRESET => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    rescue Errno::EHOSTDOWN => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    rescue Net::HTTPBadResponse => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    rescue Zlib::BufError => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    rescue Zlib::DataError => e # "incorrect header check - may be specific to ruby 2.0"
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    rescue EOFError => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    rescue SocketError => e
      @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    #rescue SystemCallError => e
    #  @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
    #rescue ArgumentError => e
    #  @task_result.logger.log_error "Argument Error: #{e}" if @task_result
    rescue Encoding::InvalidByteSequenceError => e
      @task_result.logger.log_error "Encoding error: #{e}" if @task_result
    rescue Encoding::UndefinedConversionError => e
      @task_result.logger.log_error "Encoding error: #{e}" if @task_result
    end

  response
  end

  def check_uri_exists(request_uri, missing_page_test, missing_page_code, missing_page_content, success_cases=nil)

     to_return = false

     response = http_request :get, request_uri
     return false unless response

     # try again if we got a blank page (some WAFs seem to do this?)
     if response.body == ""
       2.times do
         _log "Re-attempting #{request_uri}... verifying we should really have a blank page"
         response = http_request :get, request_uri
         next unless response
         break if response.body != ""
       end
     end

     # make sure we have a valid response
     return false unless response

     ######### BEST CASE IS WHEN WE KNOW WHAT IT SHOULD LOOK LIKE
     # if we have a positive regex, always check that first and just return it if it matches
     if success_cases

      #_log "Checking success cases: #{success_cases}"

       if success_cases[:body_regex]
         if response.body =~ success_cases[:body_regex]
           _log_good "Matched positive body regex!!! #{success_cases[:body_regex]}"
           return {
             name: request_uri,
             uri: request_uri,
             response_code: response.code,
             response_body: response.body
           }
         else
           #_log "Didn't match our positive body regex, skipping"
           return false
         end
       elsif success_cases[:header_regex]
         response.each do |header|
          _log "Checking header: '#{header}: #{response[header]}'"
          if "#{header}: #{response[header]}" =~ success_cases[:header_regex]   ### ALWAYS LOWERCASE!!!!
           _log_good "Matched positive header regex!!! #{success_cases[:header_regex]}"
           return {
             name: request_uri,
             uri: request_uri,
             response_code: response.code,
             response_body: response.body
           }
          end
        end
       return false
       end
     end
    ##############

    # otherwise fall through into our more generic checking.

     # always check for content...
     ["404", "forbidden", "Request Rejected"].each do |s|
       if (response.body =~ /#{s}/i )
         _log "Skipping #{request_uri}, contains a missing page string: #{s}"
         return false
       end
     end

     #_log "Response.code is a #{response.code.class}"

     # always check code
     if ( response.code == "301" || response.code == "302" ||
          "#{response.code}" =~ /^4\d\d/ ||  "#{response.code}" =~ /^5\d\d/ )
       _log "Ignoring #{request_uri} based on code: #{response.code}"
       return false
     end

     ## If we are able to guess based on the code, we're super lucky!
     if missing_page_test == :code
       case response.code
         when "200"
           _log_good "Clean 200 for #{request_uri}"
           to_return = {
             name: request_uri,
             uri: request_uri,
             response_code: response.code,
             response_body: response.body
           }
         when missing_page_code
           _log "Got code: #{response.code}. Same as missing page code: #{missing_page_code}. Ignoring!"
         else
           _log "Flagging #{request_uri} because of response code #{response.code}!"
           to_return = {
             name: request_uri,
             uri: request_uri,
             response_code: response.code,
             response_body: response.body
           }
       end

     ## Otherwise, let's guess based on the content. Does this page look
     ## like a missing page?
     elsif missing_page_test == :content
       if response.body[0..100] == missing_page_content[0..100]
         _log "Skipping #{request_uri} based on page content"

       else
         _log "Flagging #{request_uri} because of content!"
         to_return = {
           name: request_uri,
           uri: request_uri,
           response_code: response.code,
           response_body: response.body
          }
       end
     end

   to_return
   end

  end
end
end
