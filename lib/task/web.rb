require 'net/http'
require 'tempfile'
require 'uri'
require 'iconv'

# This module exists for common web functionality
module Intrigue
module Task
  module Web

    #
    # Download a file locally
    #
    def download_and_store(url)
      filename = "#{SecureRandom.uuid}"
      file = Tempfile.new(filename, Dir.tmpdir, 'wb+')

      @task_log.good "Attempting to download #{url} and store in #{file.path}" if @task_log

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
        @task_log.error "Invalid URI? #{e}" if @task_log
        return nil
      rescue URI::InvalidURIError => e
        #
        # XXX - This is an issue. We should catch this and ensure it's not
        # due to an underscore / other acceptable character in the URI
        # http://stackoverflow.com/questions/5208851/is-there-a-workaround-to-open-urls-containing-underscores-in-ruby
        #
        @task_log.error "Unable to request URI: #{uri} #{e}" if @task_log
        return nil
      rescue OpenSSL::SSL::SSLError => e
        @task_log.error "SSL connect error : #{e}" if @task_log
        return nil
      rescue Errno::ECONNREFUSED => e
        @task_log.error "Unable to connect: #{e}" if @task_log
        return nil
      rescue Errno::ECONNRESET => e
        @task_log.error "Unable to connect: #{e}" if @task_log
        return nil
      rescue Net::HTTPBadResponse => e
        @task_log.error "Unable to connect: #{e}" if @task_log
        return nil
      rescue Zlib::BufError => e
        @task_log.error "Unable to connect: #{e}" if @task_log
        return nil
      rescue Zlib::DataError => e # "incorrect header check - may be specific to ruby 2.0"
        @task_log.error "Unable to connect: #{e}" if @task_log
        return nil
      rescue EOFError => e
        @task_log.error "Unable to connect: #{e}" if @task_log
        return nil
      rescue SocketError => e
        @task_log.error "Unable to connect: #{e}" if @task_log
        return nil
      rescue Encoding::InvalidByteSequenceError => e
        @task_log.error "Encoding error: #{e}" if @task_log
        return nil
      rescue Encoding::UndefinedConversionError => e
        @task_log.error "Encoding error: #{e}" if @task_log
        return nil
      rescue EOFError => e
        @task_log.error "Unexpected end of file, consider looking at this file manually: #{url}" if @task_log
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
    def http_get(uri, headers={}, limit = 10, timeout=20, read_timeout=1000)

      #@task_log.log "http_get Connecting to #{uri}" if @task_log

      begin

        # XXX - We really should have a better exception here. See:
        # http://apidock.com/ruby/Net/HTTP
        raise ArgumentError, 'HTTP redirect too deep' if limit == 0

        Timeout.timeout(timeout) do

          ###
          ### XXX - it's possible we won't be able to parse this,
          ###  and we'll end up tripping a URI::InvalidURIError
          ###
          if @task_log
            unless uri =~ /^http/
              @task_log.error("Strange URI: #{uri}")
              #raise "Failing on URI: #{uri}"
            end
            #@task_log.log "Falling back to #{}"
          end

          uri_obj = URI.parse(uri)
          http = Net::HTTP.new(uri_obj.host, uri_obj.port)
          http.read_timeout = read_timeout
          http.use_ssl = (uri_obj.scheme == 'https')
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?

          # Set up the GET request with headers
          request = Net::HTTP::Get.new(uri)
          headers.each{|key,value| request.add_field(key, value)}

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

                # It's a broken URI, we need to get the base from the existing
                # URI string

                redirect_uri = "#{uri.split("/")[0..2].join("/")}#{response["location"]}"

              end

              http_get(redirect_uri, {}, limit - 1)

            else
              # Return 4XX,5XX, etc directly
              return response
          end
        end

      ### TODO - this code may be be called outside the context of a task,
      ###  meaning @task_log is not available to it. Below, we check to
      ###  make sure that it exists before attempting to log anything,
      ###  but there may be a cleaner way to do this (hopefully?). Maybe a
      ###  global logger or logging queue?
      ###
      rescue Timeout::Error
        @task_log.error "Timed out" if @task_log
      rescue URI::InvalidURIError => e
        #
        # XXX - This is an issue. We should catch this and ensure it's not
        # due to an underscore / other acceptable character in the URI
        # http://stackoverflow.com/questions/5208851/is-there-a-workaround-to-open-urls-containing-underscores-in-ruby
        #
        @task_log.error "Unable to request URI: #{uri} #{e}" if @task_log
      rescue OpenSSL::SSL::SSLError => e
        @task_log.error "SSL connect error : #{e}" if @task_log
      rescue Errno::ECONNREFUSED => e
        @task_log.error "Unable to connect: #{e}" if @task_log
      rescue Errno::ECONNRESET => e
        @task_log.error "Unable to connect: #{e}" if @task_log
      rescue Net::HTTPBadResponse => e
        @task_log.error "Unable to connect: #{e}" if @task_log
      rescue Zlib::BufError => e
        @task_log.error "Unable to connect: #{e}" if @task_log
      rescue Zlib::DataError => e # "incorrect header check - may be specific to ruby 2.0"
        @task_log.error "Unable to connect: #{e}" if @task_log
      rescue EOFError => e
        @task_log.error "Unable to connect: #{e}" if @task_log
      rescue SocketError => e
        @task_log.error "Unable to connect: #{e}" if @task_log
      rescue SystemCallError => e
        @task_log.error "Unable to connect: #{e}" if @task_log
      rescue ArgumentError => e
        @task_log.error "Argument Error: #{e}" if @task_log
      rescue Encoding::InvalidByteSequenceError => e
        @task_log.error "Encoding error: #{e}" if @task_log
      rescue Encoding::UndefinedConversionError => e
        @task_log.error "Encoding error: #{e}" if @task_log
      end
    end


=begin

  ###
  ### Expects generic content
  ###
  def parse_content_for_entities(content)
    parse_links(content)
    parse_strings(content)
    parse_seals(content)
  end

  def parse_links(content)
    URI::extract(content).each do |link|
      _create_entity("Uri", {:name => "#{link}" }) if "#{link}" =~ /^http/
    end
  end

  ###
  ### Expects a webpage's contents
  ###
  def parse_strings(content)

    # Scan for email addresses
    addrs = content.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,8}/)
    addrs.each do |addr|
      _create_entity("EmailAddress", {:name => addr})
    end

    # Scan for dns records
    dns_records = content.scan(/^[A-Za-z0-9]+\.[A-Za-z0-9]+\.[a-zA-Z]{2,6}$/)
    dns_records.each do |dns_record|
      _create_entity("DnsRecord", {:name => addr})
    end

    # Scan for interesting content
    list = content.scan(/upload/im)
    list.each do |item|
      _create_entity("Info", {:name => "File upload on #{_get_entity_attribute "name"}"})
    end

    # Scan for interesting content
    list = content.scan(/admin/im)
    list.each do |item|
      _create_entity("Info", {:name => "Admin mention on #{_get_entity_attribute "name"}"})
    end

    # Scan for interesting content
    list = content.scan(/password/im)
    list.each do |item|
      _create_entity("Info", {:name => "Password mention on #{_get_entity_attribute "name"}"})
    end

    # Scan for interesting content
    list = content.scan(/<form/im)
    list.each do |item|
      _create_entity("Info", {:name => "Form on #{_get_entity_attribute "name"}"})
    end

  end

  ###
  ### Expects a webpage
  ###
  def parse_seals(content)
    #
    # Trustwave Seal
    #
    content.scan(/sealserver.trustwave.com\/seal.js/i).each do |item|
      _create_entity("Info", {:name => "SecuritySeal: Trustwave #{_get_entity_attribute "name"}"})
    end
  end

=end


  end
end
end
