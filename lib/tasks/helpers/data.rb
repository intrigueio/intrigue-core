module Intrigue
module Task
module Data

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
    db = GeoIP.new(File.join('data', 'geolitecity', 'latest.dat'))

    begin
      _log "looking up location for #{ip}"

      #
      # This call attempts to do a lookup
      #
      loc = db.city(ip)

    rescue ArgumentError => e
      _log "Argument Error #{e}"
    rescue Encoding::InvalidByteSequenceError => e
      _log "Encoding error: #{e}"
    rescue Encoding::UndefinedConversionError => e
      _log "Encoding error: #{e}"
    end
  loc.to_h.stringify_keys
  end


end
end
end
