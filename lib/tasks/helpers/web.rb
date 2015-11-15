require 'net/http'
require 'tempfile'
require 'uri'
require 'iconv'

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

    #
    # Download a file locally. Useful for situations where we need to parse the file
    # and also useful in situations were we need to verify content-type
    #
    def download_and_store(url)
      filename = "#{SecureRandom.uuid}"
      file = Tempfile.new(filename, Dir.tmpdir, 'wb+')

      @task_result.logger.log_good "Attempting to download #{url} and store in #{file.path}" if @task_result

      begin
        uri = URI.parse(URI.encode("#{url}"))
        Net::HTTP.start(uri.host, uri.port) do |http|

          resp = http.get(uri.path)
          response_body = resp.body.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})

          # Convert encoding
          ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
          response_body = ic.iconv(resp.body + ' ')[0..-2]

          file.write(response_body)
          file.flush
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
      end

    file.path
    end

    # XXX - move this over to net-http (?)
    def http_post(uri, data)
      RestClient.post uri, data
    end

    #
    # Helper method to easily get an HTTP Response BODY
    #
    def http_get_body(uri)
      response = http_get(uri)

      ### filter body
      if response
        response_body = response.body.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
      end

    response_body
    end

    ###
    ### XXX - significant updates made to zlib, determine whether to
    ### move this over to RestClient: https://github.com/ruby/ruby/commit/3cf7d1b57e3622430065f6a6ce8cbd5548d3d894
    ###
    def http_get(uri, headers={}, limit = 10, timeout=60, read_timeout=1000)

      #@task_result.logger.log "http_get Connecting to #{uri}" if @task_result

      begin

        # XXX - We really should have a better exception here. See:
        # http://apidock.com/ruby/Net/HTTP
        raise ArgumentError, 'HTTP redirect too deep' if limit == 0

        Timeout.timeout(timeout) do
          ###
          ### XXX - it's possible we won't be able to parse this,
          ###  and we'll end up tripping a URI::InvalidURIError
          ###
          if @task_result
            unless uri =~ /^http/
              @task_result.logger.log_error("Strange URI: #{uri}")
              #raise "Failing on URI: #{uri}"
            end
          end

          uri_obj = URI.parse(uri)
          http = Net::HTTP.new(uri_obj.host, uri_obj.port)
          http.read_timeout = read_timeout
          http.use_ssl = (uri_obj.scheme == 'https')
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?

          # Set up the GET request with headers
          request = Net::HTTP::Get.new(uri)
          headers.each{|key,value| request.add_field(key, value)}

          # Set the user-agent independently
          #request.add_field('User-Agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36')

          # Make the actual request
          response = http.start {|http| http.request(request) }

          # See the various response classes here:
          # http://apidock.com/ruby/Net/HTTP
          case response
            when Net::HTTPSuccess
              ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
              response.body = ic.iconv(response.body + ' ')[0..-2]
              return response
            when Net::HTTPRedirection # 300
              # handle redirections with recursion

              # We need to construct the URI for cases where the redirect doesn't
              # include the base domain. For instance, when http://www.whatever.com/test
              # redirects to /test2

              if response['location'] =~ /^http/
                redirect_uri = "#{response['location']}"
              else

                # It's a broken URI, we need to get the base from the existing URI
                redirect_uri = "#{uri.split("/")[0..2].join("/")}#{response["location"]}"
              end

              # GET IT!
              http_get(redirect_uri, {}, limit - 1)

            else
              # Return 4XX,5XX, etc directly
              return response
          end
        end

      ### TODO - this code may be be called outside the context of a task,
      ###  meaning @task_result is not available to it. Below, we check to
      ###  make sure that it exists before attempting to log anything,
      ###  but there may be a cleaner way to do this (hopefully?). Maybe a
      ###  global logger or logging queue?
      ###
      rescue Timeout::Error
        @task_result.logger.log_error "Timed out" if @task_result
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
      rescue SystemCallError => e
        @task_result.logger.log_error "Unable to connect: #{e}" if @task_result
      rescue ArgumentError => e
        @task_result.logger.log_error "Argument Error: #{e}" if @task_result
      rescue Encoding::InvalidByteSequenceError => e
        @task_result.logger.log_error "Encoding error: #{e}" if @task_result
      rescue Encoding::UndefinedConversionError => e
        @task_result.logger.log_error "Encoding error: #{e}" if @task_result
      end
    end

     #
     # http_get_auth_resource - request a resource behind http auth
     #
     # This method is useful for bruteforcing authentication. Abstracted from
     # uri_http_auth_brute
     #
     def http_get_auth_resource(location, username,password, depth)

       unless depth > 0
         @task_result.logger.log_error "Too many redirects"
         exit
       end

       uri = URI.parse(location)
       http = Net::HTTP.new(uri.host, uri.port)
       request = Net::HTTP::Get.new(uri.request_uri,{"User-Agent" => "Intrigue!"})
       request.basic_auth(username,password)
       response = http.request(request)

       if response == Net::HTTPRedirection
         @task_result.logger.log "Redirecting to #{response['location']}"
         http_get_auth_resource(response['location'],username,password, depth-1)
       elsif response == Net::HTTPMovedPermanently
         @task_result.logger.log "Redirecting to #{response['location']}"
         http_get_auth_resource(response['location'],username,password, depth-1)
       else
         @task_result.logger.log "Got response: #{response}"
       end

     response
     end


  end
end
end
