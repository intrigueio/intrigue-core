#!/usr/bin/env ruby
require 'net/http'
require 'openssl'
require 'zlib'

# Load in checks
require_relative 'check_factory'
require_relative 'checks/base'
check_folder = File.expand_path('checks', File.dirname(__FILE__)) # get absolute directory
Dir["#{check_folder}/*.rb"].each { |file| require_relative file }

# load in CPE handling
require 'versionomy'
require_relative 'cpe'

# Load in traverse exceptions
require_relative 'traverse_exceptions'
include Intrigue::Ident::TraverseExceptions

module Intrigue
  module Ident
    
    def generate_requests_and_check(url, options)

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
            results << _match_http_response(check, response, options)
          end
        end
      end

    # Return all matches, minus the nils (non-matches)
    results.compact
    end

    def check_intrigue_uri_hash(intrigue_uri_data, options={})

      results = []

      # gather all fingeprints for each product
      # this will look like an array of checks, each with a uri and a SET of checks
      generated_checks = Intrigue::Ident::CheckFactory.all.map{|x| x.new.generate_checks("x") }.flatten

      # group by the uris, with the associated checks
      # TODO - this only currently supports the first path of the group!!!!
      grouped_generated_checks = generated_checks.group_by{|x| x[:paths].first }

      # call the check on each uri
      grouped_generated_checks.each do |ggc|

        target_url = ggc.first

        # call each check, collecting the product if it's a match
        ggc.last.each do |check|
          results << _match_uri_hash(check, intrigue_uri_data, options)
        end
      end

    # Return all matches, minus the nils (non-matches)
    results.compact
    end

    # remove bad checks we need to roll back
    def remove_bad_ident_matches(matches)
      passed_matches = []
      matches.each do |m|
        next if (m["match_type"] == "content_body" &&
                        m["matched_content"] == "(?-mix:Drupal)")

        next if (m["match_type"] == "content_cookies" &&
                        m["matched_content"] == "(?i-mx:ADRUM_BTa)" &&
                        m["product"] == "Jobvite")

        passed_matches << m
      end
    passed_matches
    end

    private

    def _construct_match_response(check, data, options={})
      calculated_version = (check[:dynamic_version].call(data) if check[:dynamic_version]) || check[:version]

      calculated_type = "a" if check[:type] == "application"
      calculated_type = "h" if check[:type] == "hardware"
      calculated_type = "o" if check[:type] == "operating_system"
      calculated_type = "s" if check[:type] == "service" # literally made up

      vendor_string = check[:vendor].gsub(" ","_")
      product_string = check[:product].gsub(" ","_")

      cpe_string = "cpe:2.3:#{calculated_type}:#{vendor_string}:#{product_string}".downcase
      cpe_string << ":#{calculated_version}".downcase if calculated_version

      to_return = {
        "type" => check[:type],
        "vendor" => check[:vendor],
        "product" => check[:product],
        "version" => calculated_version,
        "tags" => check[:tags],
        "matched_content" => check[:match_content],
        "match_type" => check[:match_type],
        "match_details" => check[:match_details],
        "hide" => check[:hide],
        "cpe" => cpe_string,
      }

      if options[:match_vulns]
        to_return["vulns"] = Cpe.new(cpe_string).vulns
      end

    to_return
    end

    def _match_uri_hash(check, data, options={})
      return nil unless check && data

      # data[:body] => page body
      # data[:headers] => block of text with headers, one per line
      # data[:cookies] => set_cookie header
      # data[:title] => parsed page title
      # data[:generator] => parsed meta generator tag
      # data[:body_md5] => md5 hash of the body
      # if type "content", do the content check

      if check[:match_type] == :content_body
        if data["details"] && data["details"]["hidden_response_data"]
          match = _construct_match_response(check,data,options) if data["details"]["hidden_response_data"] =~ check[:match_content]
        end
      elsif check[:match_type] == :content_headers
        if data["details"] && data["details"]["headers"]
          match = _construct_match_response(check,data,options) if data["details"]["headers"].join("\n") =~ check[:match_content]
        end
      elsif check[:match_type] == :content_cookies
        # Check only the set-cookie header
        if data["details"] && data["details"]["cookies"]
          match = _construct_match_response(check,data,options) if data["details"]["cookies"] =~ check[:match_content]
        end
      elsif check[:match_type] == :content_generator
        # Check only the set-cookie header
        if data["details"] && data["details"]["generator"]
          match = _construct_match_response(check,data,options) if data["details"]["generator"] =~ check[:match_content]
        end
      elsif check[:match_type] == :content_title
        # Check only the set-cookie header
        if data["details"] && data["details"]["title"]
          match = _construct_match_response(check,data,options) if data["details"]["title"] =~ check[:match_content]
        end
      elsif check[:match_type] == :checksum_body
        if data["details"] && data["details"]["response_data_hash"]
          match = _construct_match_response(check,data,options) if Digest::MD5.hexdigest(data["details"]["response_data_hash"]) == check[:checksum]
        end
      end

    match
    end

    # this method takes a check and a net/http response object and
    # constructs it into a format that's matchable. it then attempts
    # to match, and returns a match object if it matches, otherwise
    # returns nil.
    def _match_http_response(check, response,options)

      # Construct an Intrigue Entity of type Uri so we can match it
      data  = []
=begin
      json = '{
      	"id": 1572,
      	"type": "Intrigue::Entity::Uri",
      	"name": "http://69.162.37.69:80",
      	"deleted": false,
      	"hidden": false,
      	"detail_string": "Server:  | App:  | Title: Index page",
      	"details": {
      		"uri": "http://69.112.37.69:80",
      		"code": "200",
      		"port": 80,
      		"forms": false,
      		"title": "Index page",
          "generator": "Whatever",
      		"verbs": null,
      		"headers": ["content-length: 701", "last-modified: Tue, 03 Jul 2018 16:55:36 GMT", "cache-control: no-cache", "content-type: text/html"],
      		"host_id": 1571,
      		"scripts": [],
      		"products": [],
          "cookies": "",
      		"protocol": "tcp",
      		"ip_address": "69.112.37.69",
      		"javascript": [],
      		"fingerprint": [],
      		"api_endpoint": false,
      		"masscan_string": "sudo masscan -p80,443,2004,3389,7001,8000,8080,8081,8443,U:161,U:500 --max-rate 10000 -oL /tmp/masscan20180703-9816-18n0ri --range 69.162.0.0/18",
      		"app_fingerprint": [],
      		"hidden_original": "http://69.162.37.69:80",
      		"response_data_hash": "7o0r6ie5DOrJJnz1sS7RGO4XWsNn3hWykbwGkGnySWU=",
      		"server_fingerprint": [],
      		"enrichment_complete": ["enrich/uri"],
      		"include_fingerprint": [],
      		"enrichment_scheduled": ["enrich/uri"],
      		"hidden_response_data": "",
      		"hidden_screenshot_contents": """
      	},
      	"generated_at": "2018-07-04T03:43:11+00:00"
      }'
=end
      data = {}
      data["details"] = {}
      data["details"]["hidden_response_data"] = "#{response.body}"
      # construct the headers into a big string block
      headers = []
      response.each_header do |h,v|
        headers << "#{h}: #{v}"
      end
      data["details"]["headers"] = headers

      ### grab the page attributes
      match = response.body.match(/<title>(.*?)<\/title>/i)
      data["details"]["title"] = match.captures.first if match

      match = response.body.match(/<meta name="generator" content=(.*?)>/i)
      data["details"]["generator"] = match.captures.first.gsub("\"","") if match

      data["details"]["cookies"] = response.header['set-cookie']
      data["details"]["response_data_hash"] = Digest::SHA256.base64digest("#{response.body}")

      # call the actual matcher & return
      _match_uri_hash check, data, options
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
         attempts+=1

         #proxy_addr = "127.0.0.1"
         proxy_addr = nil
         #proxy_port = "8080"
         proxy_port = nil

         # set options
         opts = {}
         if uri.instance_of? URI::HTTPS
           opts[:use_ssl] = true
           opts[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
         end

         http = Net::HTTP.start(uri.host, uri.port, proxy_addr, proxy_port, opts)
         #http.set_debug_output($stdout)
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
