require 'dnsruby'
require 'nmap/program'
require 'nmap/xml'

module Intrigue
class EnrichHost < BaseTask

  def self.metadata
    {
      :name => "enrich_host",
      :pretty_name => "Enrich Host",
      :authors => ["jcran"],
      :description => "Look up all names of a given entity.",
      :references => [],
      :allowed_types => ["Host"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [{"type" => "Host", "attributes" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" }
      ],
      :created_types => []
    }
  end

  def run
    super

    opt_resolver = _get_option "resolver"
    lookup_name = _get_entity_name

    ip_addresses = []
    dns_names = []
    if lookup_name.is_ip_address?
      ip_addresses << lookup_name
    else
      dns_names << lookup_name
    end

    begin
      resolver = Dnsruby::Resolver.new(
        :nameserver => opt_resolver,
        :search => [])

        result = resolver.query(lookup_name, Dnsruby::Types::ANY)
      _log "Processing: #{result}"

      # Let us know if we got an empty result
      _log_error "Nothing?" if result.answer.empty?

      # For each of the found addresses
      result.answer.map do |resource|
        next if resource.type == Dnsruby::Types::RRSIG #TODO parsing this out is a pain, not sure if it's valuable
        _log "Adding name from: #{resource}"
        ip_addresses << resource.address.to_s if resource.respond_to? :address
        dns_names << resource.domainname.to_s if resource.respond_to? :domainname
        dns_names << resource.name.to_s.downcase
      end #end result.answer

    rescue Dnsruby::ServFail => e
      _log_error "Unable to resolve: #{@entity}, error: #{e}"
    rescue Dnsruby::NXDomain => e
      _log_error "Unable to resolve: #{@entity}, error: #{e}"
    rescue Dnsruby::ResolvTimeout => e
      _log_error "Unable to resolve, timed out: #{e}"
    rescue Errno::ENETUNREACH => e
      _log_error "Hit exception: #{e}. Are you sure you're connected?"

    #rescue Exception => e
    #  _log_error "Hit exception: #{e}"
    ensure

      temp_details = @entity.details
      temp_details["ip_addresses"] = ip_addresses.sort.uniq
      temp_details["dns_names"] = dns_names.sort.uniq
      temp_details["enriched"] = true

      @entity.lock!
      @entity.update(:details => temp_details)
      @entity.save

    end

    ## FINGERPRINT
    to_scan = _get_entity_name

    # Create a tempfile to store results
    temp_file = "#{Dir::tmpdir}/nmap_scan_#{rand(100000000)}.xml"

    # Check for IPv6
    nmap_options = ""
    nmap_options << "-6" if to_scan =~ /:/

    # shell out to nmap and run the scan
    _log "Scanning #{to_scan} and storing in #{temp_file}"
    nmap_string = "nmap #{to_scan} #{nmap_options} -O -p21,22,80,443,8080,8081,8443,10000 --max-os-tries 1 -oX #{temp_file}"
    _unsafe_system(nmap_string)

    # PARSE FILE
    Nmap::XML.new(temp_file) do |xml|
      xml.each_host do |host|

        @entity.lock!
        @entity.update(:details => @entity.details.merge({"os" => host.os.matches}))
        @entity.save

      end
    end

    _log "Ran enrichment task!"
  end

end
end
