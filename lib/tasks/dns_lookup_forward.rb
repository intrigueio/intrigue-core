require 'dnsruby'

module Intrigue
class DnsLookupForwardTask < BaseTask

  def metadata
    {
      :name => "dns_lookup_forward",
      :pretty_name => "DNS Forward Lookup",
      :authors => ["jcran"],
      :description => "Look up the IP Address of the given hostname. Grab all types of the recor  d.",
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
      @task_result.logger.log_error "Nothing?" if result.answer.empty?

      # For each of the found addresses
      result.answer.map{ |resource|
        @task_result.logger.log "Parsing #{resource}"

        # Check to see if the entity should be a DnsRecord or an IPAddress. Simply check
        # for the presence of alpha characters (see String initializer for this method)
        "#{resource.rdata}".is_ip_address? ? entity_type="IpAddress" : entity_type="DnsRecord"

        # Create the entity
        if resource.type == Dnsruby::Types::SOA
          # Will look something like this:
          # [#<Dnsruby::Name: sopcgm.ual.com.>, #<Dnsruby::Name: ualipconfig.united.com.>, 2011110851, 10800, 3600, 2592000, 600]

          resource.rdata.each do |x|
            _create_entity(entity_type, { "name" => "#{x}", "parsed_record_type" => "SOA"}) if resource.rdata.class == Dnsruby::Name
          end

        elsif resource.type == Dnsruby::Types::NS
          _create_entity(entity_type, { "name" => "#{resource.rdata}", "parsed_record_type" => "NS"})

        elsif resource.type == Dnsruby::Types::MX
          # MX records will have the rdata as follows: [10, #<Dnsruby::Name: mail2.dmz.xxxx.com.>]
          _create_entity(entity_type, { "name" => "#{resource.rdata.last}", "parsed_record_type" => "MX"})

        elsif resource.type == Dnsruby::Types::A
          _create_entity(entity_type, { "name" => "#{resource.rdata}", "parsed_record_type" => "A"})

        elsif resource.type == Dnsruby::Types::AAAA
          _create_entity(entity_type, { "name" => "#{resource.rdata}", "parsed_record_type" => "A"})

        elsif resource.type == Dnsruby::Types::CNAME
          _create_entity(entity_type, { "name" => "#{resource.rdata}", "parsed_record_type" => "CNAME"})

        elsif resource.type == Dnsruby::Types::TXT
          _create_entity("Info", { "name" => "TXT record for #{resource.name}", "data" => "#{resource.rdata}"})

          "#{resource.rdata}".split(" ").each do |x|

            _create_entity(entity_type, "name" => x.split(":").last ) if x =~ /^include:/
            _create_entity("NetBlock", "name" => x.split(":").last ) if x =~ /^ip/

          end

        else
          _create_entity("Info", { "name" => "#{resource.type} Record for #{name}", "type" => "#{resource.type}", "data" => "#{resource.rdata}" })
        end
      }

    rescue Exception => e
      @task_result.logger.log_error "Hit exception: #{e}"
    end
  end

end
end
