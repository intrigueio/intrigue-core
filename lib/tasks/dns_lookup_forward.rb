require 'dnsruby'

module Intrigue
class DnsLookupForwardTask < BaseTask

  def metadata
    {
      :name => "dns_lookup_forward",
      :pretty_name => "DNS Forward Lookup",
      :authors => ["jcran"],
      :description => "Look up the IP Address of the given hostname.",
      :references => [],
      :allowed_types => ["DnsRecord","String"],
      :example_entities => [{"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}],
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

      res = Dnsruby::Resolver.new(
        :recurse => "true",
        :query_timeout => 5,
        :nameserver => resolver)

      result = res.query(name, "ANY")
      @task_result.log_error "Nothing?" if result.answer.empty?

      # For each of the found addresses
      result.answer.map{ |resource|

        @task_result.log "Parsing #{resource}"

        # Check to see if the entity should be a DnsRecord or an IPAddress. Simply check
        # for the presence of alpha characters (see String initializer for this method)
        ( "#{resource.name}".gsub(".","").alpha? ? entity_type = "DnsRecord" : entity_type = "IpAddress" )

        # Create the entity
        if resource.type == Dnsruby::Types::NS
          _create_entity(entity_type, { "name" => "#{resource.name}", "type" => "NS", "data" => "#{resource.rdata}" })
        elsif resource.type == Dnsruby::Types::SOA
          _create_entity(entity_type, { "name" => "#{resource.name}", "type" => "SOA", "data" => "#{resource.rdata}" })
        elsif resource.type == Dnsruby::Types::MX
          _create_entity(entity_type, { "name" => "#{resource.name}", "type" => "MX", "data" => "#{resource.rdata}" })
        elsif resource.type == Dnsruby::Types::A
          _create_entity(entity_type, { "name" => "#{resource.name}", "type" => "A", "data" => "#{resource.rdata}"})
        else
          _create_entity("Info", { "name" => "#{resource.type} Record for #{name}", "type" => "#{resource.type}", "data" => "#{resource.rdata}" })
        end
      }

    rescue Exception => e
      @task_result.log_error "Hit exception: #{e}"
    end
  end

end
end
