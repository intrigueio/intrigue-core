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

include Intrigue::Task::Web

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
        response = http_request :get, "#{target_url}"

        unless response
          #puts "Unable to get a response at: #{target_url}, failing"
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

      calculated_version = (check[:dynamic_version].call(data) if check[:dynamic_version]) || check[:version] || ""
      calculated_update = (check[:dynamic_update].call(data) if check[:dynamic_update]) || check[:update] || ""

      calculated_type = "a" if check[:type] == "application"
      calculated_type = "h" if check[:type] == "hardware"
      calculated_type = "o" if check[:type] == "operating_system"
      calculated_type = "s" if check[:type] == "service" # literally made up

      vendor_string = check[:vendor].gsub(" ","_")
      product_string = check[:product].gsub(" ","_")

      version = "#{calculated_version}".gsub(" ","_")
      update = "#{calculated_update}".gsub(" ","_")

      cpe_string = "cpe:2.3:#{calculated_type}:#{vendor_string}:#{product_string}:#{version}:#{update}".downcase


      to_return = {
        "type" => check[:type],
        "vendor" => check[:vendor],
        "product" => check[:product],
        "version" => calculated_version,
        "update" => calculated_update,
        "tags" => check[:tags],
        "matched_content" => check[:match_content],
        "match_type" => check[:match_type],
        "match_details" => check[:match_details],
        "hide" => check[:hide],
        "cpe" => cpe_string,
      }

      if options[:match_vulns]
        if options[:match_vuln_method] == "api"
          to_return["vulns"] = Cpe.new(cpe_string).query_intrigue_vulndb_api
        else
          to_return["vulns"] = Cpe.new(cpe_string).query_local_nvd_json
        end
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
          match = _construct_match_response(check,data,options) if Digest::MD5.hexdigest(data["details"]["response_data_hash"]) == check[:match_content]
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

end
end
