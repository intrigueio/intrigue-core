module Intrigue
  module Task
    module Geolocation
      require_relative 'uri_helper'
      include Intrigue::Task::UriHelper

      require_relative 'web'
      require_relative 'generic'
      require 'uri'
      require 'json'

      def geolocate_ip(ip)
        config = get_config

        return nil if config.nil?

        params = {
          "api-key": config['value']
        } # this can then be expanded to accept other args.

        _log "looking up location for #{ip}"

        ip = get_host_from_ip(ip)

        if ip.nil?
          _log_error 'Could not validate validate ip. Unable to proceed with Geolocation task.'
          return nil
        end

        url = build_request(config['uri'], ip, params)

        response = http_request(:get, url.to_s)

        if response.nil?
          _log_error 'Failed to get response from Geolocation service.'
          return nil
        end

        geolocation_data = JSON.parse(response.body_utf8)
        
        unless geolocation_data.key?("ip") && geolocation_data.key?("asn") && geolocation_data.key?("country_code") 
          _log_error "Missing required hash keys in geolocation information"
          return nil
        end

        geolocation_data.except!('currency', 'threat', 'time_zone')

        _log_debug geolocation_data

        geolocation_data
      rescue StandardError => e
        _log_error "Error getting Geolocation: #{e}"

        nil
      end

      private

      def get_config
        config = _get_system_config('intrigue_global_module_config')['ipdata_api_key']

        if config.nil?
          _log_error 'Geolocation configuration not set. Unable to proceed with Geolocation task.'
          return nil
        end

        if config['value'] == 'CHANGE_ME' || config['value'].nil?
          _log_error 'Geolocation api key has not been set. Unable to proceed with Geolocation task.'
          return nil
        end

        if config['uri'].nil?
          _log_error 'Geolocation base api url not found. Unable to proceed with Geolocation task.'
          return nil
        end

        config
      end

      def build_request(base_url, ip, params)
        URI::HTTPS.build(host: base_url, path: "/#{ip}", query: URI.encode_www_form(params))
      end
    end
  end
end
