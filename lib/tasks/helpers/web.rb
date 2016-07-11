require 'net/http'
require 'tempfile'
require 'uri'

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
          http.read_timeout = 10
          resp = http.get(uri.path)
          response_body = resp.body.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})

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
        return response.body.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
      end

    nil
    end

    ###
    ### XXX - significant updates made to zlib, determine whether to
    ### move this over to RestClient: https://github.com/ruby/ruby/commit/3cf7d1b57e3622430065f6a6ce8cbd5548d3d894
    ###
    def http_get(uri_string, headers={}, limit = 10, open_timeout=15, read_timeout=15)

      #@task_result.logger.log "http_get Connecting to #{uri}" if @task_result
      response = nil
      begin

        attempts=0
        max_attempts=10
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.73 Safari/537.36"
        found = false

        uri = URI.parse uri_string

        until( found || attempts >= max_attempts)
         #@task_result.logger.log "Getting #{uri}, attempt #{attempts}" if @task_result
         attempts+=1

         http = Net::HTTP.new(uri.host,uri.port)
         http.read_timeout = 10
         http.open_timeout = 10

         path = uri.path
         path = "/" if path==""

         #request = Net::HTTP::Get.new(path,{'User-Agent'=>user_agent})
         if uri.instance_of? URI::HTTPS
           http.use_ssl=true
           http.verify_mode = OpenSSL::SSL::VERIFY_NONE
         end

         response = http.get(path)

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
      rescue Net::OpenTimeout => e
        @task_result.logger.log_error "Timeout : #{e}" if @task_result
      rescue Net::ReadTimeout => e
        @task_result.logger.log_error "Timeout : #{e}" if @task_result
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

     # List of checks for body of the response
     def http_body_checks
       [
         ###
         ### Security Seals
         ###
         # http://baymard.com/blog/site-seal-trust
         # https://vagosec.org/2014/11/clubbing-seals/
         #
         { :regex => /Norton Secured, Powered by Symantec/,
           :finding_name => "Norton Security Seal"},
         { :regex => /PathDefender/,
           :finding_name => "McAfee Pathdefender Security Seal"},
         ### Marketing / Tracking
         {:regex => /urchin.js/, :finding_name => "Google Analytics"},
         {:regex => /optimizely/, :finding_name => "Optimizely"},
         {:regex => /trackalyze/, :finding_name => "Trackalyze"},
         {:regex => /doubleclick.net|googleadservices/,
           :finding_name => "Google Ads"},
         {:regex => /munchkin.js/, :finding_name => "Marketo"},
         {:regex => /Olark live chat software/, :finding_name => "Olark"},
         ### External accounts
         {:regex => /http:\/\/www.twitter.com.*?/,
           :finding_name => "Twitter Account"},
         {:regex => /http:\/\/www.facebook.com.*?/,
           :finding_name => "Facebook Account"},
         ### Technologies
         #{:regex => /javascript/, :finding => "Javascript"},
         {:regex => /jquery.js/, :finding_name => "JQuery"},
         {:regex => /bootstrap.css/, :finding_name => "Twitter Bootstrap"},
         ### Platform
         {:regex => /[W|w]ordpress/, :finding_name => "Wordpress"},
         {:regex => /[D|d]rupal/, :finding_name => "Drupal"},
         ### Provider
         {:regex => /Content Delivery Network via Amazon Web Services/,
           :finding_name => "Amazon Cloudfront"},
         ### Wordpress Plugins
         { :regex => /wp-content\/plugins\/.*?\//, :finding_name => "Wordpress Plugin" },
         { :regex => /xmlrpc.php/, :finding_name => "Wordpress API"},
         #{:regex => /Yoast WordPress SEO plugin/, :finding_name => "Yoast Wordress SEO Plugin"},
         #{:regex => /PowerPressPlayer/, :finding_name => "Powerpress Wordpress Plugin"},
         ###
       ]
     end


  end
end
end
