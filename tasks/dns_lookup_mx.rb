require 'resolv'

class DnsLookupMxTask < BaseTask

  def metadata
    { 
      :name => "dns_lookup_mx",
      :pretty_name => "DNS MX Lookup",
      :authors => ["jcran"],
      :description => "Look up the MX records of the given DNS record.",
      :references => [],
      :allowed_types => ["DnsRecord"],
      :example_entities => [{:type => "DnsRecord", :attributes => {:name => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" }
      ],
      :created_types => ["DnsRecord", "IpAddress"]
    }
  end

  def run
    super

    resolver = _get_option "resolver"
    name = _get_entity_attribute "name"

    begin
      # XXX - we should probably call this a couple times to deal
      # with round-robin DNS & load balancers. We'd need to merge results
      # across the queries
      resources = Resolv::DNS.open do |dns|
        dns.getresources(name, Resolv::DNS::Resource::IN::MX)
      end

      resources.each do |r|

        # Create a DNS record
        _create_entity("DnsRecord", {
          :name => r.exchange.to_s,
          :description => "Mail server for #{name}",
          :preference => r.preference })

        # Grab the IP addresses at the same time
        Resolv.new.getaddresses(r.exchange.to_s).map{ |address|
          _create_entity("IpAddress", {
            :name => address }
          )}


      end




    rescue Exception => e
      @task_log.error "Hit exception: #{e}"
    end
  end

end
