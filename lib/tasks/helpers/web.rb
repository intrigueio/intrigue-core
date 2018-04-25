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

    def fingerprint_uri(uri)

      results = []

      # first collect all products
      @fingerprints = [
        Intrigue::Fingerprint::AspNet,
        Intrigue::Fingerprint::Atlassian,
        Intrigue::Fingerprint::Drupal,
        Intrigue::Fingerprint::Example,
        Intrigue::Fingerprint::Joomla,
        Intrigue::Fingerprint::LimeSurvey,
        Intrigue::Fingerprint::Magento,
        Intrigue::Fingerprint::MediaWiki,
        Intrigue::Fingerprint::Spring,
        Intrigue::Fingerprint::Tomcat,
        Intrigue::Fingerprint::Wordpress
      ]

      # gather all fingeprints for each product
      # this will look like an array of fingerprints, each with a uri and a SET of checks

      generated_fingerprints = @fingerprints.map{|x| x.new.generate_fingerprints(uri) }.flatten

      # group by the uris, with the associated checks
      grouped_generated_fingerprints = generated_fingerprints.group_by{|x| x[:uri]}

      # call the check on each uri
      grouped_generated_fingerprints.each do |ggf|

        # get the response
        response = http_request :get, "#{ggf.first}"

        if response

          # call each check, collecting the product if it's a match
          ggf.last.map{|x| x[:checklist] }.each do |checklist|

            checklist.each do |check|

              # if type "content", do the content check
              if check[:type] == :content_body
                # Do each content check, call the dynamic name if we have it,
                # otherwise, just give it a static name
                # note that content should be a regex!!!!
                if "#{response.body}" =~ check[:content]
                  if check[:dynamic_version]
                    results << { :version => check[:dynamic_version].call(response), :name => check[:name], :match => check[:type] } ||
                      { :name => check[:name], :version => check[:version], :match => check[:type] }
                  else
                    results << { :name => check[:name], :version => check[:version], :match => check[:type] }
                  end
                end

              elsif check[:type] == :content_headers
                # Check each header
                response.each do |h|
                  next unless check[:content] =~ h
                  if check[:dynamic_version]
                    results << { :version => check[:dynamic_version].call(response), :name => check[:name], :match => check[:type] } ||
                      { :name => check[:name], :version => check[:version], :match => check[:type] }
                  else
                    results << { :name => check[:name], :version => check[:version], :match => check[:type] }
                  end
                end

              elsif check[:type] == :content_cookies
                # Check only the set-cookie header
                if response.header['set-cookie'] =~ check[:content]
                  if check[:dynamic_version]
                    results << { :version => check[:dynamic_version].call(response), :name => check[:name], :match => check[:type] } ||
                      { :name => check[:name], :version => check[:version], :match => check[:type] }
                  else
                    results << { :name => check[:name], :version => check[:version], :match => check[:type] }
                  end
                end

              elsif check[:type] == :checksum_body
                if Digest::MD5.hexdigest("#{response.body}") == check[:checksum]
                  if check[:dynamic_version]
                    results << { :version => check[:dynamic_version].call(response), :name => check[:name], :match => check[:type] } ||
                      { :name => check[:name], :version => check[:version], :match => check[:type] }
                  else
                    results << { :name => check[:name], :version => check[:version], :match => check[:type] }
                  end
                end

              end

            end
          end

        end # if response
      end
    results
    end


    #
    # Download a file locally. Useful for situations where we need to parse the file
    # and also useful in situations were we need to verify content-type
    #
    def download_and_store(url)
      filename = "#{SecureRandom.uuid}"
      file = Tempfile.new(filename, Dir.tmpdir) #, 'wb+')

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
      end

    file.path
    end

    # XXX - move this over to net-http (?)
    def http_post(uri, data)
      RestClient.post(uri, data)
    end

    #
    # Helper method to easily get an HTTP Response BODY
    #
    def http_get_body(uri)
      response = http_request(:get,uri)

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
    def http_request(method, uri_string, credentials=nil, headers={}, data=nil, limit = 10, open_timeout=15, read_timeout=15)

      response = nil
      begin

        # set user agent
        headers["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.73 Safari/537.36"

        attempts=0
        max_attempts=10
        found = false

        uri = URI.parse uri_string

        unless uri
          _log error "Unable to parse URI from: #{uri_string}"
          return
        end

        until( found || attempts >= max_attempts)
         @task_result.logger.log "Getting #{uri}, attempt #{attempts}" if @task_result
         attempts+=1

         global_config = Intrigue::Config::GlobalConfig.new
         if global_config.config["http_proxy"]
           proxy_addr = global_config.config["http_proxy"]["host"]
           proxy_port = global_config.config["http_proxy"]["port"]
           proxy_user = global_config.config["http_proxy"]["user"]
           proxy_pass = global_config.config["http_proxy"]["pass"]
         end

         # set options
         opts = {}
         if uri.instance_of? URI::HTTPS
           opts[:use_ssl] = true
           opts[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
         end

         http = Net::HTTP.start(uri.host, uri.port, proxy_addr, proxy_port, opts)
         http.read_timeout = 20
         http.open_timeout = 20

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
           request.body(data)
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

         # set the headers
         headers.each do |k,v|
           request[k] = v
         end

         # handle credentials
         if credentials
           request.basic_auth(credentials[:username],credentials[:password])
         end

         # get tehe response
         response = http.request(request)

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
      rescue ArgumentError => e
        @task_result.logger.log_error "Unable to open connection: #{e}" if @task_result
      rescue Net::OpenTimeout => e
        @task_result.logger.log_error "Timeout : #{e}" if @task_result
      rescue Net::ReadTimeout => e
        @task_result.logger.log_error "Timeout : #{e}" if @task_result
      rescue Errno::ETIMEDOUT => e
        @task_result.logger.log_error "Timeout : #{e}" if @task_result
      rescue Errno::ENETUNREACH => e
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


     def download_and_extract_metadata(uri,extract_content=true)

       begin
         # Download file and store locally before parsing. This helps prevent mime-type confusion
         # Note that we don't care who it is, we'll download indescriminently.
         file = open(uri, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})

         # Parse the file
         yomu = Yomu.new file

         # create a uri for everything
         _create_entity "Document", {
             "content_type" => file.content_type,
             "name" => "#{uri}",
             "uri" => "#{uri}",
             "metadata" => yomu.metadata }

         # Handle audio files
         if yomu.metadata["Content-Type"] == "audio/mpeg" # Handle MP3/4
           _create_entity "Person", {"name" => yomu.metadata["meta:author"], "origin" => uri }
           _create_entity "Person", {"name" => yomu.metadata["creator"], "origin" => uri }
           _create_entity "Person", {"name" => yomu.metadata["xmpDM:artist"], "origin" => uri }

         elsif yomu.metadata["Content-Type"] == "application/pdf" # Handle PDF
           _create_entity "Person", {"name" => yomu.metadata["Author"], "origin" => uri, "modified" => yomu.metadata["Last-Modified"] } if yomu.metadata["Author"]
           _create_entity "Person", {"name" => yomu.metadata["meta:author"], "origin" => uri, "modified" => yomu.metadata["Last-Modified"] } if yomu.metadata["meta:author"]
           _create_entity "Person", {"name" => yomu.metadata["dc:creator"], "origin" => uri, "modified" => yomu.metadata["Last-Modified"] } if yomu.metadata["dc:creator"]
           _create_entity "Organization", {"name" => yomu.metadata["Company"], "origin" => uri, "modified" => yomu.metadata["Last-Modified"] } if yomu.metadata["Company"]
           _create_entity "SoftwarePackage", {"name" => yomu.metadata["producer"], "origin" => uri, "modified" => yomu.metadata["Last-Modified"] } if yomu.metadata["producer"]
           _create_entity "SoftwarePackage", {"name" => yomu.metadata["xmp:CreatorTool"], "origin" => uri, "modified" => yomu.metadata["Last-Modified"] } if yomu.metadata["Company"]
         end

         # Look for entities in the text of the entity
         parse_entities_from_content(uri,yomu.text) if extract_content

       # Don't die if we lose our connection to the tika server
       rescue RuntimeError => e
         @task_result.logger.log "ERROR Unable to download file: #{e}"
       rescue EOFError => e
         @task_result.logger.log "ERROR Unable to download file: #{e}"
       rescue OpenURI::HTTPError => e     # don't die if we can't find the file
         @task_result.logger.log "ERROR Unable to download file: #{e}"
       rescue URI::InvalidURIError => e     # handle invalid uris
         @task_result.logger.log "ERROR Unable to download file: #{e}"
       rescue Errno::EPIPE => e
         @task_result.logger.log "ERROR Unable to contact Tika: #{e}"
       rescue JSON::ParserError => e
         @task_result.logger.log "ERROR parsing JSON: #{e}"
       end

     end

     ###
     ### Entity Parsing
     ###
     def parse_entities_from_content(source_uri, content)
       parse_email_addresses_from_content(source_uri, content)
       parse_dns_records_from_content(source_uri, content)
       parse_phone_numbers_from_content(source_uri, content)
       #parse_uris_from_content(source_uri, content)
     end

     def parse_email_addresses_from_content(source_uri, content)

       @task_result.logger.log "Parsing text from #{source_uri}" if @task_result

       # Make sure we have something to parse
       unless content
         @task_result.logger.log_error "No content to parse, returning" if @task_result
         return nil
       end

       # Scan for email addresses
       addrs = content.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,8}/)
       addrs.each do |addr|
         x = _create_entity("EmailAddress", {"name" => addr, "origin" => source_uri}) unless addr =~ /.png$|.jpg$|.gif$|.bmp$|.jpeg$/
       end

     end

     def parse_dns_records_from_content(source_uri, content)

       @task_result.logger.log "Parsing text from #{source_uri}" if @task_result

       # Make sure we have something to parse
       unless content
         @task_result.logger.log_error "No content to parse, returning" if @task_result
         return nil
       end

       # Scan for dns records
       dns_records = content.scan(/^[A-Za-z0-9]+\.[A-Za-z0-9]+\.[a-zA-Z]{2,6}$/)
       dns_records.each do |dns_record|
         x = _create_entity("DnsRecord", {"name" => dns_record, "origin" => source_uri})
       end
     end

     def parse_phone_numbers_from_content(source_uri, content)

       @task_result.logger.log "Parsing text from #{source_uri}" if @task_result

       # Make sure we have something to parse
       unless content
         @task_result.logger.log_error "No content to parse, returning" if @task_result
         return nil
       end

       # Scan for phone numbers
       phone_numbers = content.scan(/((\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4})/)
       phone_numbers.each do |phone_number|
         x = _create_entity("PhoneNumber", { "name" => "#{phone_number[0]}", "origin" => source_uri})
       end
     end

     def parse_uris_from_content(source_uri, content)

       @task_result.logger.log "Parsing text from #{source_uri}" if @task_result

       # Make sure we have something to parse
       unless content
         @task_result.logger.log_error "No content to parse, returning" if @task_result
         return nil
       end

       # Scan for uris
       urls = content.scan(/https?:\/\/[\S]+/)
       urls.each do |url|
         _create_entity("Uri", {"name" => url, "uri" => url, "origin" => source_uri })
       end
     end


  end
end
end
