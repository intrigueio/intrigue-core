require 'resolv'
module Intrigue
class DnsBruteTldTask < BaseTask

  def metadata
    {
      :name => "dns_brute_tld",
      :pretty_name => "DNS TLD Bruteforce",
      :authors => ["jcran"],
      :description => "DNS TLD Bruteforce",
      :references => [],
      :allowed_types => ["DnsRecord","String"],
      :example_entities => [{:type => "DnsRecord", :attributes => {:name => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" },
        {:name => "use_file", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "brute_file", :type => "String", :regex => "filename", :default => "dns_tld.list" },
        {:name => "check_cctlds", :type => "Boolean", :regex => "boolean", :default => false }
      ],
      :created_types => ["DnsRecord","IpAddress"]
    }
  end

  def run
    super

    # Find more info here:
    # http://www.icann.org/en/tlds/
    #
    # TODO - @chrisjohnriley passed along this:
    # https://mxr.mozilla.org/mozilla-central/source/netwerk/dns/effective_tld_names.dat?raw=1

    basename = _get_entity_attribute "name"

    opt_resolver = _get_option "resolver"
    opt_use_file = _get_option "use_file"
    opt_filename = _get_option "brute_file"
    opt_cctld    = _get_option "check_cctlds"

    @resolver = Resolv.new

    # Create the brute list (from a file, or a provided list)
    if opt_use_file
      @task_log.log "Using file #{opt_filename}"
      tld_list = File.open("#{$intrigue_basedir}/data/#{opt_filename}","r").read.split("\n")
      tld_list = tld_list.map {|x| x.downcase }
    else
      @task_log.log "Using built-in list"
      tld_list = ['biz', 'cc', 'co.uk', 'com', 'cn', 'de', 'edu', 'info',
        'int', 'io', 'net', 'org', 'mobi', 'name', 'pro', 'xxx', 'us']
    end

  if opt_cctld
    @task_log.log "Country code TLDs configured"

    #short_cctld_list = ['au','co.uk', 'cn', 'de', 'fr', 'it', 'nl', 'no', 'pl', 'ru', 'se', 'sk', 'to', 'us']

    # FULL LIST
    cctld_list = ['ac', 'ad', 'ae', 'af', 'ag', 'ai', 'al', 'am', 'an', 'ao',
    'aq', 'ar', 'as', 'at', 'au', 'aw', 'ax', 'az', 'ba', 'bb', 'bd', 'be', 'bf',
    'bg', 'bh', 'bi', 'bj', 'bm', 'bn', 'bo', 'br', 'bs', 'bt', 'bv', 'bw', 'by',
    'bzca', 'cat', 'cc', 'cd', 'cf', 'cg', 'ch', 'ci', 'ck', 'cl', 'cm', 'cn', 'co',
    'cr', 'cu', 'cv', 'cx', 'cy', 'cz', 'de', 'dj', 'dk', 'dm', 'do', 'dz', 'ec', 'ee',
    'eg', 'er', 'es', 'et', 'eu', 'fi', 'fj', 'fk', 'fm', 'fo', 'fr', 'ga', 'gb', 'gd',
    'ge', 'gf', 'gg', 'gh', 'gi', 'gl', 'gm', 'gn', 'gp', 'gq', 'gr', 'gs', 'gt', 'gu',
    'gw', 'gy', 'hk', 'hm', 'hn', 'hr', 'ht', 'hu', 'id', 'ie', 'il', 'im', 'in',
    'io', 'iq', 'ir', 'is', 'it', 'je', 'jm', 'jo', 'jp', 'ke', 'kg', 'kh', 'ki', 'km',
    'kn', 'kp', 'kr', 'kw', 'ky', 'kz', 'la', 'lb', 'lc', 'li', 'lk', 'lr', 'ls', 'lt',
    'lu', 'lv', 'ly', 'ma', 'mc', 'md', 'me', 'mg', 'mh', 'mk', 'ml', 'mm', 'mn', 'mo',
    'mp', 'mq', 'mr', 'ms', 'mt', 'mu', 'mv', 'mw', 'mx', 'my', 'mz', 'na', 'nc', 'ne',
    'nf', 'ng', 'ni', 'nl', 'no', 'np', 'nr', 'nu', 'nz', 'om', 'pa', 'pe', 'pf', 'pg',
    'ph', 'pk', 'pl', 'pm', 'pn', 'pr', 'ps', 'pt', 'pw', 'py', 'qa', 're', 'ro',
    'rs', 'ru', 'rw', 'sa', 'sb', 'sc', 'sd', 'se', 'sg', 'sh', 'si', 'sj', 'sk', 'sl',
    'sm', 'sn', 'so', 'sr', 'st', 'su', 'sv', 'sy', 'sz', 'tc', 'td', 'tel', 'tf', 'tg',
    'th', 'tj', 'tk', 'tl', 'tm', 'tn', 'to', 'tp', 'tr', 'tt', 'tv', 'tw', 'tz', 'ua',
    'ug', 'uk', 'us', 'uy', 'uz', 'va', 'vc', 've', 'vg', 'vi', 'vn', 'vu', 'wf', 'ws',
    'ye', 'yt', 'za', 'zm', 'zw']

    # add all the individual country code domains in
    cctld_list.each { |x| tld_list << "#{x}" }
  end

### The usual suspects need to be dealt with here. These are largely
### useless for our purposes.
=begin
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Airforce.com.com"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"54.201.82.69"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Airforce.com.net"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"74.221.212.214"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Airforce.com.org"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"23.21.224.150"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Airforce.com.jobs"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"50.19.241.165"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Airforce.com.ninja"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"127.0.53.53"}}

{"type"=>"DnsRecord", "attributes"=>{"name"=>"Air.com.co"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"72.52.4.91"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Air.com.com"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"54.201.82.69"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Air.com.net"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"106.186.123.143"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Air.com.org"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"23.21.224.150"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Air.com.jobs"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"50.19.241.165"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Air.com.ninja"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"127.0.53.53"}}

{"type"=>"DnsRecord", "attributes"=>{"name"=>"Bathtub.com.com"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"54.201.82.69"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Bathtub.com.net"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"74.221.212.214"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Bathtub.com.org"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"23.21.224.150"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Bathtub.com.jobs"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"50.19.241.165"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Bathtub.com.cn"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"222.73.20.195"}}
{"type"=>"DnsRecord", "attributes"=>{"name"=>"Bathtub.com.ninja"}}
{"type"=>"IpAddress", "attributes"=>{"name"=>"127.0.53.53"}}
=end

    @task_log.good "Using tld list: #{tld_list}"

    resolved_addresses = []

    tld_list.each do |tld|
      begin

        # Calculate the domain name
        domain = "#{basename}.#{tld}"

        # Try to resolve
        resolved_address = @resolver.getaddress(domain)
        @task_log.good "Resolved Address #{resolved_address} for #{domain}" if resolved_address

        # If we resolved, create the right entities
        if resolved_address
          _create_entity("DnsRecord", {:name => domain})
          _create_entity("IpAddress", {:name => resolved_address})
        end

      rescue Exception => e
        @task_log.error "Hit exception: #{e}"
      end
    end
  end

end
end
