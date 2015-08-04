require 'geoip'
module Intrigue
class GeolocateHostTask < BaseTask

  def metadata
    {
      :name => "geolocate_host",
      :pretty_name => "Geolocate Host",
      :authors => ["jcran"],
      :description => "Performs a geolocation based on an IP address.",
      :references => [],
      :allowed_types => ["IpAddress"],
      :example_entities => [{:type => "IpAddress", :attributes => {:name => "192.0.78.13"}}],
      :allowed_options => [],
      :created_types => ["PhysicalLocation"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    ip_address = _get_entity_attribute "name"

    ###
    ### XXX - this will only work if our start path is correct
    ###  and the file exists (see get_latest.sh in /data/)
    ###

    @db = GeoIP.new(File.join('data', 'geolitecity', 'latest.dat'))

    begin
      @task_log.log "looking up location for #{ip_address}"

      #
      # This call attempts to do a lookup
      #
      loc = @db.city(ip_address)

      if loc
        @task_log.log "adding location for #{ip_address}"
        _create_entity("PhysicalLocation", {
          :name => "#{loc.latitude} #{loc.longitude}",
          :zip => loc.postal_code.encode('UTF-8', :invalid => :replace),
          :city => loc.city_name.encode('UTF-8', :invalid => :replace),
          :state => loc.region_name.encode('UTF-8', :invalid => :replace),
          :country => loc.country_name.encode('UTF-8', :invalid => :replace),
          :longitude => loc.longitude,
          :latitude => loc.latitude})
        end
      rescue ArgumentError => e
        @task_log.log "Argument Error #{e}"
      rescue Encoding::InvalidByteSequenceError => e
        @task_log.log "Encoding error: #{e}"
      rescue Encoding::UndefinedConversionError => e
        @task_log.log "Encoding error: #{e}"

      end

  end

end
end
