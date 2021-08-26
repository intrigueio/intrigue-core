module Intrigue
module Task
module Data

  def dev_server_name_patterns
    [
      /-stage$/,/-staging$/,/-dev$/,/-development$/,/-test$/,/-qa$/,
      /^staging-/,/^dev-/,/^development-/,/^test-/,/^qa-/,
      /^staging\./,/^dev\./,/^development\./,/^test\./,/^qa\./,
      /^test/,/^staging/,/^qa/
    ] # possibly too aggressive
  end

  def common_dns_permuation_list
    [
      { type: "both", :permutation => "0" },
      { type: "both", :permutation => "1" },
      { type: "both", :permutation => "2" },
      { type: "both", :permutation => "3" },
      { type: "both", :permutation => "4" },
      { type: "both", :permutation => "5" },
      { type: "both", :permutation => "6" },
      { type: "both", :permutation => "7" },
      { type: "both", :permutation => "8" },
      { type: "both", :permutation => "9" },
      { type: "both", :permutation => "w" },
      { type: "both", :permutation => "x" },
      { type: "both", :permutation => "www" },
      { type: "both", :permutation => "dev" },
      { type: "both", :permutation => "prd" },
      { type: "both", :permutation => "prod" },
      { type: "both", :permutation => "production" },
      { type: "both", :permutation => "stg" },
      { type: "both", :permutation => "stage" },
      { type: "both", :permutation => "staging" },
      { type: "both", :permutation => "test" },
      # prefix-only
      { type: "prefix", :permutation => "dev-" },
      { type: "prefix", :permutation => "prd-" },
      { type: "prefix", :permutation => "prod-" },
      { type: "prefix", :permutation => "production-" },
      { type: "prefix", :permutation => "stg-" },
      { type: "prefix", :permutation => "stage-" },
      { type: "prefix", :permutation => "staging-" },
      { type: "prefix", :permutation => "test-" },
      # suffix-only
      { type: "suffix", :permutation => "-dev" },
      { type: "suffix", :permutation => "-prd" },
      { type: "suffix", :permutation => "-prod" },
      { type: "suffix", :permutation => "-production" },
      { type: "suffix", :permutation => "-stg" },
      { type: "suffix", :permutation => "-stage" },
      { type: "suffix", :permutation => "-staging" },
      { type: "suffix", :permutation => "-test" }
    ]
  end

  def _service_name_for(port_num,proto)
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
      next unless line.match /#{filter}/
      range = line.split(",").first
      ranges << range.gsub(/^0*/,"").gsub("/8",".0.0.0/8")
    end
  ranges
  end

  def simple_web_creds
   [
      {:username => "admin",         :password => "admin"},
      {:username => "administrator", :password => "administrator"},
      {:username => "anonymous",     :password => "anonymous"},
      {:username => "cisco",         :password => "cisco"},
      {:username => "demo",          :password => "demo"},
      {:username => "demo1",         :password => "demo1"},
      {:username => "guest",         :password => "guest"},
      {:username => "test",          :password => "test"},
      {:username => "test1",         :password => "test1"},
      {:username => "test123",       :password => "test123"},
      {:username => "test123!!",     :password => "test123!!"}
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

  # Some domains provide a cert which is valid for many other domains
  # this is, sometimes, very annoying, as you can't really be sure if the
  # other domains are related to your organization. We know the following
  # domains below are those that will host a single "universal" certificate
  # and thus, this list exists to scope those out of the normal collection
  # process. More here:
  # - https://blog.cloudflare.com/introducing-universal-ssl/
  #
  def get_universal_cert_domains
    [
      "acquia-sites.com",
      "careers.talemetry.com",
      "cdn.myqcloud.com",
      "chinacloudsites.cn",
      "chinanetcenter.com",
      "cloudflare.com",
      "cloudflaressl.com",
      "distilnetworks.com",
      "edgecastcdn.net",
      "edlio.net", # https://edlio.com/
      "fastly.net",
      "freshdesk.com",
      "helloworld.com",
      "hexagon-cdn.com",# TODO - worth revisiting,may include related hosts
      "incapsula.com",
      "jiveon.com",
      "kavasa.in",
      "lithium.com",
      "pantheon.io",
      "sucuri.net",
      "swagcache.com",
      "wpengine.com",
      "yottaa.net",
      "zohohost.com"
    ]
  end

  def issueable_tcp_ports
    [
      { port: "3389", issue: "exposed_sensitive_service", service_name: "RDP service", severity: 2 },
      { port: "135", issue: "exposed_sensitive_service", service_name: "SMB Service", severity: 2 },
      { port: "445", issue: "exposed_sensitive_service", service_name: "SMB Service", severity: 2 },
      { port: "4786", issue: "exposed_sensitive_service", service_name: "Cisco Smart Install", severity: 2 },
      { port: "49152", issue: "exposed_sensitive_service", service_name: "Windows RPC Service", severity: 2 },
      { port: "49154", issue: "exposed_sensitive_service", service_name: "Windows RPC-over-Http Service", severity: 2 }
    ]
  end

  def fingerprintable_udp_ports
    [53, 161].sort.uniq
  end

  def fingerprintable_tcp_ports
    [21, 22, 23, 25, 110, 2181, 3299, 3306, 3389, 4786, 5672,
      6379, 7001, 8649, 9100, 9200, 9201, 11211, 27017, 27018].concat(scannable_web_ports).sort.uniq
  end

  def scannable_web_ports
    [
      80,81,82,83,84,85,88,443,888,3000,6443,7443,
      8000,8080,8081,8087,8088,8089,8090,8095,
      8098,8161,8180,8443,8880,8888,9443,10000,10001
    ]
  end

  def scannable_udp_ports

    udp_ports = ""
    udp_ports << "53,"      # dns
    udp_ports << "123,"     # ntp
    udp_ports << "135,"     # msrpc
    udp_ports << "139,"     # netbios session
    udp_ports << "161,"     # snmp
    udp_ports << "500,"     # isakmp
    udp_ports << "631,"     # ipp
    udp_ports << "1434,"    # msrpc
    udp_ports << "1900,"    # upnp
    udp_ports << "2049,"    # nfs
    udp_ports << "17185"    # vxworks https://blog.rapid7.com/2010/08/02/new-vxworks-vulnerabilities/

  udp_ports.split(",")
  end

  def scannable_tcp_ports

    # https://duo.com/decipher/mapping-the-internet-whos-who-part-three
    # https://docs.oracle.com/cd/E16340_01/core.1111/e10105/portnums.htm
    # https://svn.nmap.org/nmap/nmap-services
    # https://docs.google.com/spreadsheets/d/1r_IriqmkTNPSTiUwii_hQ8Gwl2tfTUz8AGIOIL-wMIE/pub?output=html

    tcp_ports = ""
    tcp_ports << "21,"
    tcp_ports << "22,"
    tcp_ports << "23,"
    tcp_ports << "35,"
    tcp_ports << "53,"
    tcp_ports << "80,"
    tcp_ports << "81,"
    tcp_ports << "106,"
    tcp_ports << "110,"
    tcp_ports << "135,"
    tcp_ports << "143,"
    tcp_ports << "443,"
    tcp_ports << "445,"
    tcp_ports << "465,"
    tcp_ports << "502,"
    tcp_ports << "503,"
    tcp_ports << "587,"
    tcp_ports << "993,"             # imaps
    tcp_ports << "995,"             # pops
    tcp_ports << "1090,"            # java rmi
    tcp_ports << "1098,"            # java rmi
    tcp_ports << "4444,"            # java rmi
    tcp_ports << "1723,"            # pptp
    tcp_ports << "1883,"
    tcp_ports << "2181,"            # zookeeper
    tcp_ports << "2222,"
    tcp_ports << "2375,"            # docker
    tcp_ports << "2376,"            # docker
    tcp_ports << "2888,"
    tcp_ports << "3299,"            # SAPRouter
    tcp_ports << "3306,"            # mysql
    tcp_ports << "3389,"            # RDP
    tcp_ports << "3888,"
    tcp_ports << "4190,"
    tcp_ports << "4443,"            # HTTPS
    tcp_ports << "4444,"            # Bind / jboss
    tcp_ports << "4445,"            # jboss
    tcp_ports << "4505,"            # salt stack
    tcp_ports << "4506,"            # salt stack
    tcp_ports << "4786,"            # Cisco Smart Install
    tcp_ports << "4848,"            # Glassfish
    tcp_ports << "5000,"            # Oracle WebLogic Server Node Manager Port
    tcp_ports << "5555,"            # HP Data Protector
    tcp_ports << "5556,"            # HP Data Protector
    tcp_ports << "5672,"
    tcp_ports << "5900,5901,"       # vnc
    tcp_ports << "6379,"            # redis
    tcp_ports << "6443,"
    tcp_ports << "7001,"            # Oracle WebLogic Server Listen Port for Administration Server
    tcp_ports << "7002,"            # Oracle WebLogic Server Listen Port for Administration Server
    tcp_ports << "7003,"            # Oracle WebLogic Server
    tcp_ports << "7004,"            # Oracle WebLogic Server
    tcp_ports << "7070,"            # Oracle WebLogic Server
    tcp_ports << "7071,"            # Oracle WebLogic Server
    tcp_ports << "7443,"
    tcp_ports << "7777,"
    tcp_ports << "8000,"            # Oracle WebLogic Server
    tcp_ports << "8001,"            # Oracle WebLogic Server Listen Port for Managed Server
    tcp_ports << "8002,"            # Oracle WebLogic Server
    tcp_ports << "8003,"            # Oracle WebLogic Server
    tcp_ports << "8009,"
    tcp_ports << "8032,"
    tcp_ports << "8080,8081,"       # HTTP
    tcp_ports << "8278,"
    tcp_ports << "8291,"
    tcp_ports << "8443,"
    tcp_ports << "8649,"            # ganglia
    tcp_ports << "8686,"            # JMX
    tcp_ports << "8883,"
    tcp_ports << "9000,"            # Oracle WebLogic Server
    tcp_ports << "9001,"            # Oracle WebLogic Server
    tcp_ports << "9002,"            # Oracle WebLogic Server
    tcp_ports << "9003,"            # Oracle WebLogic Server
    tcp_ports << "9012,"            # JMX
    tcp_ports << "9091,9092,"
    tcp_ports << "9094,"
    tcp_ports << "9100,"            # jetdirect
    tcp_ports << "9200,9201,"         # elasticsearch
    tcp_ports << "9300,9301,"         # elasticsearch
    tcp_ports << "9443,"
    tcp_ports << "9503,"            # Oracle WebLogic Server
    tcp_ports << "10999,"            # java rmi
    tcp_ports << "10443,"
    tcp_ports << "11099,"            # java rmi
    tcp_ports << "11111,"            # jboss
    tcp_ports << "11211,"            # memcached
    tcp_ports << "11443,"
    tcp_ports << "11994,"
    tcp_ports << "12443,"
    tcp_ports << "13443,"
    tcp_ports << "20443,"
    tcp_ports << "27017,27018,27019," # mongodb
    tcp_ports << "22222,"
    tcp_ports << "30443,"
    tcp_ports << "40443,"
    tcp_ports << "45000,"            # JDWP
    tcp_ports << "45001,"            # JDWP
    tcp_ports << "47001,"            # java rmi
    tcp_ports << "47002,"            # java rmi
    tcp_ports << "49152,"
    tcp_ports << "49154,"
    tcp_ports << "50500,"            # JMX
    tcp_ports << "53413"

  tcp_ports.split(",")
  end

end
end
end
