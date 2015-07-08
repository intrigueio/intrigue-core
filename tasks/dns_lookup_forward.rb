require 'resolv'

class DnsLookupForwardTask < BaseTask

  def metadata
    { :version => "1.0",
      :name => "dns_lookup_forward",
      :pretty_name => "DNS Forward Lookup",
      :authors => ["jcran"],
      :description => "Look up the IP Address of the given hostname.",
      :references => [],
      :allowed_types => ["DnsRecord"],
      :example_entities => [{:type => "DnsRecord", :attributes => {:name => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" }
      ],
      :created_types => ["IpAddress"]
    }
  end

  def run
    super

    resolver = _get_option "resolver"
    name = _get_entity_attribute "name"

    begin
      # Get the addresses
      resolved_addresses = Resolv.new.getaddresses(name)

      # XXX - we should probably .getaddresses() a couple times to deal
      # with round-robin DNS & load balancers. We'd need to merge results
      # across the queries

      # For each of the found addresses
      resolved_addresses.map{ |address|
        _create_entity("IpAddress", {
          :name => address }
        )}

    rescue Exception => e
      @task_log.error "Hit exception: #{e}"
    end
  end

end
