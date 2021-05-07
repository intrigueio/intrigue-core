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

  def make_threaded_http_requests_from_queue(work_q, threads=10)
    # Create a pool of worker threads to work on the queue
    responses = []
    workers = (0...threads).map do
      Thread.new do
        begin
          #_log "Getting request"
          while request_uri = work_q.pop(true)
            result = http_request :get, request_uri
            responses.append(result)
          end # end while
        rescue ThreadError
        end
      end
    end; "ok"
    workers.map(&:join); "ok"

    return responses
  end

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
      _log_error "Unable to connect to site!" if @task_result
      return false
    end

    # check for sanity
    unless response.body_utf8 && response_two.body
      _log_error "Empty body!" if @task_result
      return false
    end
    
    # check to make sure we don't just go down the rabbit hole
    # some pages print back our uri, so first remove that if it exists
    unless response.body_utf8.gsub(request_page_one,"") && response_two.body.gsub(request_page_two,"")
      _log_error "Cowardly refusing to test - different responses on our missing page checks" if @task_result
      return false
    end

    # Default to code
    missing_page_test = :code
    # But select based on the response to our random page check
    case response.code
      when "404"
        _log "Using CODE as missing page test, missing page will give a 404" if @task_result
        missing_page_test = :code
      when "200"
        _log "Using CONTENT as missing page test, missing page will give a 200" if @task_result
        missing_page_test = :content
        missing_page_content = response.body_utf8
      else
        _log "Defaulting to CODE as missing page test, missing page will give a #{response.code}" if @task_result
        missing_page_test = :code
        missing_page_code = response.code
    end
    ##########################

    matching_urls = Queue.new

    # Create a pool of worker threads to work on the queue
    workers = (0...threads).map do
      Thread.new do
        begin
          #_log "Getting request"
          while request_details = work_q.pop(true)

            request_uri = "#{uri}#{request_details[:path]}"

            # Do the check
            _log "Checking #{request_uri}"

            # request details will have regexes if we want to check, so just pass it directly
            result = check_uri_exists(request_uri, missing_page_test, missing_page_code, missing_page_content, request_details)

            if result
              # create a new entity for each one if we specified that
              _create_entity("Uri", { "name" => result[:uri] }) if create_url

              # dump it into our queue so we can push matches back
              matching_urls.push({ start: request_uri, final: result[:uri] })

              result[:proof]=result[:uri]
            
              # Create a linked issue if the type exists
              if _linkable_issue_exists "#{request_details[:issue_type]}"
                _log "Creating linked issue of type: #{request_details[:issue_type]}" if @task_result
                _create_linked_issue(request_details[:issue_type], result.except!(:name)) 
              else
                # Generic fallback 
                _log "Creating issue of type: #{request_details[:issue_type]}" if @task_result
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

  def http_post(uri, data, params)
    http_request(:post, uri, nil, params, data)
  end

  #
  # Helper method to easily get an HTTP Response BODY
  #
  def http_get_body(uri, credentials=nil, headers={})
    response = http_request(:get, uri, credentials, headers)

    ### filter body
    if response
      return response.body_utf8
    end

  nil
  end

  def http_request(method, uri_string, credentials=nil, headers={}, data=nil, follow_redirects=true, timeout=10)

    # set user agent unless one was provided
    unless headers["User-Agent"]
      headers["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36"
    end

    begin 

      options = {}

      # always
      options[:timeout] = timeout
      options[:ssl_verifyhost] = 0
      options[:ssl_verifypeer] = false
      
      # avoid many open sockets in CLOSE_WAIT state
      options[:forbid_reuse] = true 

      # follow redirects if we're told
      if follow_redirects 
        options[:followlocation] = true
      end

      # if we're a post, set our body 
      if method == :post || method == :put
        options[:body] = data
      end

      # merge in credentials, must be in format :user => 'username', :password => 'password'
      if credentials
        options[:userpwd] = "#{credentials[:user]}:#{credentials[:password]}"
      end

      # create a request
      request = Typhoeus::Request.new(uri_string, {
        method: method,
        headers: headers
      }.merge!(options))

      # run the request 
      response = request.run

    # catch th
    rescue Typhoeus::Errors::TyphoeusError => e
      @task_result.logger.log_error "Request Error: #{e}" if @task_result
      puts "Request Error: #{e}" unless @task_result
    end

    # fail unless we get a response
    unless response
      if @task_result
        @task_result.logger.log_error "Unable to get a response"
      else
        puts "Unable to get a response"
      end
      return nil 
    end
    
  response
  end

  def check_uri_exists(request_uri, missing_page_test, missing_page_code="404", missing_page_content="", success_cases=nil)

     to_return = false

     response = http_request :get, request_uri
     return false unless response

     # try again if we got a backoff
     while response.kind_of? Net::HTTPTooManyRequests do 
      _log "Got a backoff, sleeping ~60s"
      sleep 30 + rand(60)
      response = http_request :get, request_uri
     end

     return false if response.kind_of? Net::HTTPNotFound

     # try again if we got a blank page (some WAFs seem to do this?)
     if !response.code == "404" && response.body_utf8 == ""
       2.times do
         _log "Re-attempting #{request_uri}... verifying we should really have a blank page" if @task_result
         response = http_request :get, request_uri 
         next unless response
         break if response.body_utf8 != ""
       end
     end

     # again make sure we have a valid response
     return false unless response

     ######### BEST CASE IS WHEN WE KNOW WHAT IT SHOULD LOOK LIKE
     # if we have a positive regex, always check that first and just return it if it matches
     if success_cases

      #_log "Checking success cases: #{success_cases}"

       if success_cases[:body_regex]
         if response.body_utf8.match(success_cases[:body_regex])
          
          out = {
            name: request_uri,
            uri: request_uri,
            response_code: response.code,
            response_body: response.body_utf8
          }

          # check to make sure we're not part of our excluded 
          if success_cases[:exclude_body_regex] && response.body_utf8.match(success_cases[:exclude_body_regex])
            _log_error "Matched exclude body regex!!! #{success_cases[:exlude_body_regex]}" if @task_result
            return nil
          else
            _log_good "Matched positive body regex!!! #{success_cases[:body_regex]}" if @task_result
            return out
          end

         else
           #_log "Didn't match our positive body regex, skipping"
           return nil
         end

       elsif success_cases[:header_regex]
         response.each_header do |header|
          _log "Checking header: '#{header}: #{response[header]}'"
          if "#{header}: #{response[header]}".match(success_cases[:header_regex])   ### ALWAYS LOWERCASE!!!!
           _log_good "Matched positive header regex!!! #{success_cases[:header_regex]}" if @task_result
           return {
             name: request_uri,
             uri: request_uri,
             response_code: response.code,
             response_body: response.body_utf8
           }
          end
        end
       return nil
       end
     end
    ##############

    # otherwise fall through into our more generic checking.

     #_log "Response.code is a #{response.code.class}"

     # always check code
     if ( response.code == "301" || response.code == "302" ||
          "#{response.code}".match(/^4\d\d/) ||  "#{response.code}".match(/^5\d\d/) )
        
        # often will be redirected or 500'd and that doesnt count as existence 
       _log "Ignoring #{request_uri} based on redirect code: #{response.code}" if @task_result
       return false
     end

     ## If we are able to guess based on the code, we're super lucky!
     if missing_page_test == :code
       case response.code
         when "200"
           _log_good "Clean 200 for #{request_uri}" if @task_result
           to_return = {
             name: request_uri,
             uri: request_uri,
             response_code: response.code,
             response_body: response.body_utf8
           }
         when missing_page_code
           _log "Got code: #{response.code}. Same as missing page code: #{missing_page_code}. Ignoring!" if @task_result
         else
           _log "Flagging #{request_uri} because of response code #{response.code}!" if @task_result
           to_return = {
             name: request_uri,
             uri: request_uri,
             response_code: response.code,
             response_body: response.body_utf8
           }
       end

     ## Otherwise, let's guess based on the content. Does this page look
     ## like a missing page?
     elsif missing_page_test == :content

       # check for default content...
       ["404", "forbidden", "Request Rejected"].each do |s|
         if (response.body_utf8.match(/#{s}/i) )
           _log "Skipping #{request_uri}, contains a missing page string: #{s}" if @task_result
           return false
         end
       end

       if response.body_utf8[0..100] == missing_page_content[0..100]
         _log "Skipping #{request_uri} based on page content" if @task_result

       else
         _log "Flagging #{request_uri} because of content!" if @task_result
         to_return = {
           name: request_uri,
           uri: request_uri,
           response_code: response.code,
           response_body: response.body_utf8
          }
       end
     end

   to_return
   end

  end
end
end
