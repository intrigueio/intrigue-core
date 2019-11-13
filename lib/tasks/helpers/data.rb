module Intrigue
module Task
module Data

  def dev_server_name_patterns
    [
      /-stage$/, /-staging$/,/-dev$/,/-development$/,/-test$/,/-qa$/, 
      /^staging-/,/^dev-/,/^development-/,/^test-/,/^qa-/,
      /^staging\./,/^dev\./,/^development\./,/^test\./,/^qa\./,
      /^test/,/^staging/,/^qa/
    ] # possibly too aggressive
  end

  def _allocated_ipv4_ranges(filter="ALLOCATED")
    ranges = []
    file = File.open("#{$intrigue_basedir}/data/iana/ipv4-address-space.csv","r")
    file.read.split("\n").each do |line|
      next unless line =~ /#{filter}/
      range = line.split(",").first
      ranges << range.gsub(/^0*/, "").gsub("/8",".0.0.0/8")
    end
  ranges
  end

  def simple_web_creds
   [
      {:username => "admin",          :password => "admin"},
      {:username => "administrator",  :password => "administrator"},
      {:username => "anonymous",      :password => "anonymous"},
      {:username => "cisco",          :password => "cisco"},
      {:username => "demo",           :password => "demo"},
      {:username => "demo1",          :password => "demo1"},
      {:username => "guest",          :password => "guest"},
      {:username => "test",           :password => "test"},
      {:username => "test1",          :password => "test1"},
      {:username => "test123",        :password => "test123"},
      {:username => "test123!!",      :password => "test123!!"}
    ]
  end

  def geolocate_ip(ip)

    begin 
      db = MaxMindDB.new("#{$intrigue_basedir}/data/geolitecity/GeoLite2-City.mmdb", MaxMindDB::LOW_MEMORY_FILE_READER)

      _log "looking up location for #{ip}"

      #
      # This call attempts to do a lookup
      #
      location = db.lookup(ip)

      #translate the hash to remove some of the multiingual stuff
      hash = {}

      hash["city"] = location.to_hash["city"]["names"]["en"] if location.to_hash["city"]
      hash["continent"] = location.to_hash["continent"]["names"]["en"] if location.to_hash["continent"]
      hash["continent_code"] = location.to_hash["continent"]["code"] if location.to_hash["continent"]
      hash["country"] = location.to_hash["country"]["names"]["en"] if location.to_hash["country"]
      hash["country_code"] = location.to_hash["country"]["iso_code"] if location.to_hash["country"]
      hash.merge(location.to_hash["location"]) if location.to_hash["location"]
      hash["postal"] = location.to_hash["postal"]["code"] if location.to_hash["postal"]
      hash["registered_country"] = location.to_hash["registered_country"]["names"]["en"] if location.to_hash["registered_country"]
      hash["registered_country_code"] = location.to_hash["registered_country"]["iso_code"] if location.to_hash["registered_country"]
      hash["subdivisions"] = location.to_hash["subdivisions"].map{|s| s["names"]["en"] } if location.to_hash["subdivisions"]
      
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
  end


end
end
end
