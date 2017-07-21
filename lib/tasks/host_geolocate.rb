module Intrigue
class GeolocateHostTask < BaseTask

  def self.metadata
    {
      :name => "geolocate_host",
      :pretty_name => "Geolocate Host",
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

    ###
    ### XXX - this will only work if our start path is correct
    ###  and the file exists (see get_latest.sh in /data/)
    ###

    @db = GeoIP.new(File.join('data', 'geolitecity', 'latest.dat'))

    begin
      _log "looking up location for #{ip_address}"

      #
      # This call attempts to do a lookup
      #
      loc = @db.city(ip_address)

      if loc
        _log "adding location for #{ip_address}"
        _create_entity("PhysicalLocation", {
          "name" => "#{loc.latitude} #{loc.longitude}",
          "zip" => loc.postal_code,
          "city" => loc.city_name,
          "state" => loc.region_name,
          "country" => loc.country_name,
          "longitude" => loc.longitude,
          "latitude" => loc.latitude})
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
