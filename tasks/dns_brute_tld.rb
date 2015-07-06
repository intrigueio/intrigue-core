require 'resolv'

class DnsBruteTldTask < BaseTask

  def metadata
    { :version => "1.0",
      :name => "dns_brute_tld",
      :pretty_name => "DNS TLD Bruteforce",
      :authors => ["jcran"],
      :description => "DNS TLD Bruteforce",
      :references => [],
      :allowed_types => ["DnsRecord"],
      :example_entities => [{:type => "DnsRecord", :attributes => {:name => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "IPAddress", :default => "8.8.8.8" }
      ],
      :created_types => ["DnsRecord","IpAddress"]
    }
  end

  def run
    super

    basename = _get_entity_attribute "name"

    @resolver = Resolv.new

    resolver = _get_option "resolver"

    # Find more info here:
    # http://www.icann.org/en/tlds/
    #
    # @chrisjohnriley passed along this:
    # https://mxr.mozilla.org/mozilla-central/source/netwerk/dns/effective_tld_names.dat?raw=1

=begin
  if @user_options['cctld_list']
    cctld_list = @user_options['cctld_list']
  else
    cctld_list = ['ac', 'ad', 'ae', 'af', 'ag', 'ai', 'al', 'am', 'an', 'ao', 'aq', 'ar',
    'as', 'at', 'au', 'aw', 'ax', 'az', 'ba', 'bb', 'bd', 'be', 'bf', 'bg',
    'bh', 'bi', 'bj', 'bm', 'bn', 'bo', 'br', 'bs', 'bt', 'bv', 'bw', 'by', 'bzca',
    'cat', 'cc', 'cd', 'cf', 'cg', 'ch', 'ci', 'ck', 'cl', 'cm', 'cn', 'co',
    'cr', 'cu', 'cv', 'cx', 'cy', 'cz', 'de', 'dj', 'dk', 'dm', 'do', 'dz', 'ec', 'ee',
    'eg', 'er', 'es', 'et', 'eu', 'fi', 'fj', 'fk', 'fm', 'fo', 'fr', 'ga', 'gb', 'gd', 'ge',
    'gf', 'gg', 'gh', 'gi', 'gl', 'gm', 'gn', 'gp', 'gq', 'gr', 'gs', 'gt', 'gu', 'gw',
    'gy', 'hk', 'hm', 'hn', 'hr', 'ht', 'hu', 'id', 'ie', 'il', 'im', 'in',
    'io', 'iq', 'ir', 'is', 'it', 'je', 'jm', 'jo', 'jp', 'ke', 'kg', 'kh', 'ki', 'km',
    'kn', 'kp', 'kr', 'kw', 'ky', 'kz', 'la', 'lb', 'lc', 'li', 'lk', 'lr', 'ls', 'lt', 'lu',
    'lv', 'ly', 'ma', 'mc', 'md', 'me', 'mg', 'mh', 'mk', 'ml', 'mm', 'mn', 'mo',
    'mp', 'mq', 'mr', 'ms', 'mt', 'mu', 'mv', 'mw', 'mx', 'my', 'mz', 'na',
    'nc', 'ne', 'nf', 'ng', 'ni', 'nl', 'no', 'np', 'nr', 'nu', 'nz', 'om',
    'pa', 'pe', 'pf', 'pg', 'ph', 'pk', 'pl', 'pm', 'pn', 'pr', 'pro', 'ps', 'pt', 'pw',
    'py', 'qa', 're', 'ro', 'rs', 'ru', 'rw', 'sa', 'sb', 'sc', 'sd', 'se', 'sg', 'sh', 'si',
    'sj', 'sk', 'sl', 'sm', 'sn', 'so', 'sr', 'st', 'su', 'sv', 'sy', 'sz', 'tc', 'td', 'tel',
    'tf', 'tg', 'th', 'tj', 'tk', 'tl', 'tm', 'tn', 'to', 'tp', 'tr', 'tt', 'tv',
    'tw', 'tz', 'ua', 'ug', 'uk', 'us', 'uy', 'uz', 'va', 'vc', 've', 'vg', 'vi', 'vn', 'vu',
    'wf', 'ws', 'xxx', 'ye', 'yt', 'za', 'zm', 'zw']
  end
=end

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

    gtld_list = ['co', 'co.uk', 'com' ,'net', 'biz', 'org', 'int', 'mil', 'edu',
    'biz', 'info', 'name', 'pro', 'aero', 'coop', 'museum', 'asia', 'cat', 'jobs',
    'mobi', 'tel', 'travel', 'arpa', 'gov', "us", "cn", "to", "xxx", "io", "ninja"]

    @task_log.log "Using gtld list: #{gtld_list}"

    resolved_addresses = []

    gtld_list.each do |tld|
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
