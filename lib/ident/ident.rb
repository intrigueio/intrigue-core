#!/usr/bin/env ruby
require 'net/http'
require 'openssl'
require 'zlib'

require_relative 'lib/check_factory'
require_relative 'lib/checks/base'
check_folder = File.expand_path('lib/checks', File.dirname(__FILE__)) # get absolute directory
Dir["#{check_folder}/*.rb"].each { |file| require_relative file }

module Intrigue
  module Ident

    VERSION=0.1

    def generate_requests_and_check(url)

      results = []

      # gather all fingeprints for each product
      # this will look like an array of checks, each with a uri and a SET of checks
      generated_checks = Intrigue::Ident::CheckFactory.all.map{|x| x.new.generate_checks(url) }.flatten

      # group by the uris, with the associated checks
      # TODO - this only currently supports the first path of the group!!!!
      grouped_generated_checks = generated_checks.group_by{|x| x[:paths].first }

      # call the check on each uri
      grouped_generated_checks.each do |ggc|

        target_url = ggc.first

        # get the response
        response = _http_request :get, "#{target_url}"

        unless response
          puts "Unable to get a response at: #{target_url}, failing"
          return nil
        end

        # Go ahead and match it up if we got a response!
        if response
          # call each check, collecting the product if it's a match
          ggc.last.each do |check|
            results << _check_response(check, response)
          end
        end
      end

    # Return all matches, minus the nils (non-matches)
    results.compact
    end

    private

    # this method takes a check and returns a ~match object if it matches, otherwise
    # returns nil.
    def _check_response(check, response)

      # if type "content", do the content check
      if check[:type] == :content_body
        match = {
          :version => (check[:dynamic_version].call(response) if check[:dynamic_version]) || check[:version],
          :name => check[:name],
          :match => check[:type],
          :hide => check[:hide]
        } if "#{response.body}" =~ check[:content]

      elsif check[:type] == :content_headers

        # construct the headers into a big string block
        header_string = ""
        response.each_header do |h,v|
          header_string << "#{h}: #{v}\n"
        end

        match = {
          :version => (check[:dynamic_version].call(response) if check[:dynamic_version]) || check[:version],
          :name => check[:name],
          :match => check[:type],
          :hide => check[:hide]
        } if header_string =~ check[:content]

      elsif check[:type] == :content_cookies
        # Check only the set-cookie header
        match = {
          :version => (check[:dynamic_version].call(response) if check[:dynamic_version]) || check[:version],
          :name => check[:name],
          :match => check[:type],
          :hide => check[:hide]
        } if response.header['set-cookie'] =~ check[:content]

      elsif check[:type] == :checksum_body
        match = {
          :version => (check[:dynamic_version].call(response) if check[:dynamic_version]) || check[:version],
          :name => check[:name],
          :match => check[:type],
          :hide => check[:hide]
        } if Digest::MD5.hexdigest("#{response.body}") == check[:checksum]
      end
    match
    end

    def _http_request(method, uri_string, credentials=nil, headers={}, data=nil, limit = 10, open_timeout=15, read_timeout=15)

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
         #puts "Getting #{uri}, attempt #{attempts}"
         attempts+=1

         # proxy configuration, disabled for now
         #if $config["http_proxy"]
         # proxy_addr = $config["http_proxy"]["host"]
         # proxy_port = $config["http_proxy"]["port"]
         # proxy_user = $config["http_proxy"]["user"]
         # proxy_pass = $config["http_proxy"]["pass"]
         #end
         proxy_addr = nil
         proxy_port = nil



         # set options
         opts = {}
         if uri.instance_of? URI::HTTPS
           opts[:use_ssl] = true
           opts[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
         end

         http = Net::HTTP.start(uri.host, uri.port, proxy_addr, proxy_port, opts)
         #http.set_debug_output($stdout) if _get_system_config "debug"
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

         # set the headers
         headers.each do |k,v|
           request[k] = v
         end

         # handle credentials
         #if credentials
         # request.basic_auth(credentials[:username],credentials[:password])
         #end

         # get the response
         response = http.request(request)

         if response.code=="200"
           break
         end

         if (response.header['location']!=nil)
           newuri=URI.parse(response.header['location'])
           if(newuri.relative?)
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
      #  puts "TypeError - unknown failure"
      rescue ArgumentError => e
        puts "Unable to open connection: #{e}"
      rescue Net::OpenTimeout => e
        puts "Timeout : #{e}"
      rescue Net::ReadTimeout => e
        puts "Timeout : #{e}"
      rescue Errno::ETIMEDOUT => e
        puts "Timeout : #{e}"
      rescue Errno::EINVAL => e
        puts "Unable to connect: #{e}"
      rescue Errno::ENETUNREACH => e
        puts "Unable to connect: #{e}"
      rescue Errno::EHOSTUNREACH => e
        puts "Unable to connect: #{e}"
      rescue URI::InvalidURIError => e
        #
        # XXX - This is an issue. We should catch this and ensure it's not
        # due to an underscore / other acceptable character in the URI
        # http://stackoverflow.com/questions/5208851/is-there-a-workaround-to-open-urls-containing-underscores-in-ruby
        #
        puts "Unable to request URI: #{uri} #{e}"
      rescue OpenSSL::SSL::SSLError => e
        puts "SSL connect error : #{e}"
      rescue Errno::ECONNREFUSED => e
        puts "Unable to connect: #{e}"
      rescue Errno::ECONNRESET => e
        puts "Unable to connect: #{e}"
      rescue Net::HTTPBadResponse => e
        puts "Unable to connect: #{e}"
      rescue Zlib::BufError => e
        puts "Unable to connect: #{e}"
      rescue Zlib::DataError => e # "incorrect header check - may be specific to ruby 2.0"
        puts "Unable to connect: #{e}"
      rescue EOFError => e
        puts "Unable to connect: #{e}"
      rescue SocketError => e
        puts "Unable to connect: #{e}"
      #rescue SystemCallError => e
      #  puts "Unable to connect: #{e}"
      #rescue ArgumentError => e
      #  puts "Argument Error: #{e}"
      rescue Encoding::InvalidByteSequenceError => e
        puts "Encoding error: #{e}"
      rescue Encoding::UndefinedConversionError => e
        puts "Encoding error: #{e}"
      end

    response
    end

end
end
