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
        # we need our files to do our job
        return nil unless File.exist? "#{$intrigue_basedir}/data/maxmind/GeoIP2-City.mmdb"
        return nil unless File.exist? "#{$intrigue_basedir}/data/maxmind/GeoLite2-ASN.mmdb"

        begin
          city_db = MaxMindDB.new("#{$intrigue_basedir}/data/maxmind/GeoIP2-City.mmdb",MaxMindDB::LOW_MEMORY_FILE_READER)
          asn_db = MaxMindDB.new("#{$intrigue_basedir}/data/maxmind/GeoLite2-ASN.mmdb",MaxMindDB::LOW_MEMORY_FILE_READER)
    
          _log "looking up location for #{ip}"
    
          #
          # This call attempts to do a lookup
          #
          location = city_db.lookup(ip)
          asn = asn_db.lookup(ip)
          return unless location.found? && asn.found?
          
          # build the results hash
          
          hash = {}
          hash[:city] = location.city.name(:en)
          hash[:continent] = location.continent.name(:en)
          hash[:continent_code] = location.continent.code
          hash[:country] = location.country.name(:en)
          hash[:country_code] = location.country.iso_code
          hash[:latitute] = location.location.latitude
          hash[:longitude] = location.location.longitude
          hash[:accuracy_radius] = location.location.accuracy_radius
          hash[:time_zone] = location.location.time_zone
          hash[:postal] = location.postal.code
          hash[:asn] = {}
          hash[:asn][:name] = asn.to_hash["autonomous_system_organization"] if asn.to_hash["autonomous_system_organization"]
          hash[:asn][:asn] = asn.to_hash["autonomous_system_number"] if asn.to_hash["autonomous_system_number"]
          hash[:asn][:route] = asn.to_hash["network"] if asn.to_hash["network"]

          # check if the required keys are present
          required_keys = [:country_code, :country, :longitude, :latitude]
          required_keys.each do |h|
            return nil unless hash.key?(h)
          end

          required_asn_keys = [:name, :asn, :route]
          required_asn_keys.each do |ha|
            return nil unless hash[:asn].key?(ha)
          end
    
        rescue RuntimeError => e
          _log "Error reading file: #{e}"
        rescue ArgumentError => e
          _log "Argument Error #{e}"
        rescue Encoding::InvalidByteSequenceError => e
          _log "Encoding error: #{e}"
        rescue Encoding::UndefinedConversionError => e
          _log "Encoding error: #{e}"
        end
        
        
        hash
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
