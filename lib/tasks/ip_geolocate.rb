module Intrigue
module Task
class IpGeolocate < BaseTask

  def self.metadata
    {
      :name => "ip_geolocate",
      :pretty_name => "Geolocate IP Address",
      :authors => ["jcran"],
      :description => "Performs a geolocation based on an IP address.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "192.0.78.13"}}],
      :allowed_options => [],
      :created_types => ["PhysicalLocation"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    ip_address = _get_entity_name
    location_hash = geolocate_ip(ip_address)

    _set_entity_detail "geolocation", location_hash

    location_hash_with_name = {"name" => "#{location_hash["city"]} #{location_hash["country"]}"}.merge(location_hash)

    begin
      if location_hash
        _log "creating location for #{ip_address}: #{location_hash["city_name"]} #{location_hash["country_name"]}"
        _create_entity("PhysicalLocation", location_hash_with_name)
      end
    rescue ArgumentError => e
      _log "Argument Error #{e}"
    rescue Encoding::InvalidByteSequenceError => e
      _log "Encoding error: #{e}"
    rescue Encoding::UndefinedConversionError => e
      _log "Encoding error: #{e}"

    end

  end
end
end
end
