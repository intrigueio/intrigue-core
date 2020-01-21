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

  def _service_name_for(port_num, proto)
    service_name = nil
    file = File.open("#{$intrigue_basedir}/data/service-names-port-numbers.csv","r")
    file.read.split("\n").each do |line|
      data = line.split(",")
      line_port_num = data[1]
      if line_port_num.to_i == port_num.to_i
        if "#{data[2]}".upcase == proto.upcase
          service_name = "#{data[0]}".upcase if data[0]
        end
      end
    end
    service_name || "UNKNOWN"
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

  def cymru_ip_whois_lookup(ip)
    whois_detail = Intrigue::Client::Search::Cymru::IPAddress.new.whois(ip)
    { 
      :net_asn => "AS#{whois_detail[0]}",
      :net_block => "#{whois_detail[1]}",
      :net_country_code => "#{whois_detail[2]}",
      :net_rir => "#{whois_detail[3]}",
      :net_allocation_date => "#{whois_detail[4]}",
      :net_name => "#{whois_detail[5]}"
    }
  end

  def get_internal_domains
    ["ec2.internal"]
  end

  def get_cdn_domains
    [
      "hexagon-cdn.com",
      "edgecastcdn.net",
      "akamaitechnologies.com",
      "static.akamaitechnologies.com",
      "1e100.net"
    ]   
  end


  def get_universal_cert_domains
    [
      "acquia-sites.com",
      "careers.talemetry.com",
      "chinanetcenter.com",
      "chinacloudsites.cn",
      "cloudflare.com",
      "cloudflaressl.com",
      "distilnetworks.com",
      "edgecastcdn.net",
      "helloworld.com",
      "hexagon-cdn.com", # TODO - worth revisiting, may include related hosts
      "fastly.net",
      "freshdesk.com",
      "jiveon.com",
      "incapsula.com",
      "lithium.com",
      "sucuri.net",
      "swagcache.com",
      "wpengine.com",
      "yottaa.net"
    ]
  end
  


  def geolocate_ip(ip)

    return nil unless File.exist? "#{$intrigue_basedir}/data/geolitecity/GeoLite2-City.mmdb"

    begin 
      db = MaxMindDB.new("#{$intrigue_basedir}/data/geolitecity/GeoLite2-City.mmdb", MaxMindDB::LOW_MEMORY_FILE_READER)

      _log "looking up location for #{ip}"

      #
      # This call attempts to do a lookup
      #
      location = db.lookup(ip)

      #translate the hash to remove some of the multiingual stuff
      hash = {}

      hash[:city] = location.to_hash["city"]["names"]["en"] if location.to_hash["city"]
      hash[:continent] = location.to_hash["continent"]["names"]["en"] if location.to_hash["continent"]
      hash[:continent_code] = location.to_hash["continent"]["code"] if location.to_hash["continent"]
      hash[:country] = location.to_hash["country"]["names"]["en"] if location.to_hash["country"]
      hash[:country_code] = location.to_hash["country"]["iso_code"] if location.to_hash["country"]
      hash.merge(location.to_hash["location"].map { |k, v| [k.to_sym, v] }.to_h) if location.to_hash["location"]
      hash[:postal] = location.to_hash["postal"]["code"] if location.to_hash["postal"]
      hash[:registered_country] = location.to_hash["registered_country"]["names"]["en"] if location.to_hash["registered_country"]
      hash[:registered_country_code] = location.to_hash["registered_country"]["iso_code"] if location.to_hash["registered_country"]
      hash[:subdivisions] = location.to_hash["subdivisions"].map{|s| s["names"]["en"] } if location.to_hash["subdivisions"]
      
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
