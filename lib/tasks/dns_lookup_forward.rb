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
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" },
        {:name => "record_types", :type => "String", :regex => "alpha_numeric_list", :default => "ANY" }
      ],
      :created_types => ["IpAddress"]
    }
  end

  def run
    super

    opt_resolver = _get_option "resolver"
    record_types = _get_option "record_types"
    name = _get_entity_attribute "name"

    begin

      res = Dnsruby::Resolver.new(
        :recurse => "true",
        :query_timeout => 5,
        :nameserver => opt_resolver,
        :search => [])

      result = res.query(name, "ANY")
      @task_result.logger.log "Processing: #{result}"

      # Let us know if we got an empty result
      @task_result.logger.log_error "Nothing?" if result.answer.empty?

      # For each of the found addresses
      result.answer.map do |resource|
        # Check to see if the entity should be a DnsRecord or an IPAddress. Simply check
        # for the presence of alpha characters (see String initializer for this method)
        "#{resource.rdata}".is_ip_address? ? entity_type="IpAddress" : entity_type="DnsRecord"

        # Create the entity
        if resource.type == Dnsruby::Types::SOA
          # Will look something like this:
          # [#<Dnsruby::Name: sopcgm.ual.com.>, #<Dnsruby::Name: ualipconfig.united.com.>, 2011110851, 10800, 3600, 2592000, 600]

          resource.rdata.each do |x|
            if resource.rdata.class == Dnsruby::Name
              _create_entity(entity_type, { "name" => "#{x}", "parsed_record_type" => "SOA"}) if record_types.include?("SOA") || record_types.include?("ANY")
            end
          end

        elsif resource.type == Dnsruby::Types::NS
          _create_entity(entity_type, { "name" => "#{resource.rdata}", "parsed_record_type" => "NS"}) if record_types.include?("NS") || record_types.include?("ANY")

        elsif resource.type == Dnsruby::Types::MX
          # MX records will have the rdata as follows: [10, #<Dnsruby::Name: mail2.dmz.xxxx.com.>]
          _create_entity(entity_type, { "name" => "#{resource.rdata.last}", "parsed_record_type" => "MX"}) if record_types.include?("MX") || record_types.include?("ANY")

        elsif resource.type == Dnsruby::Types::A
          _create_entity(entity_type, { "name" => "#{resource.rdata}", "parsed_record_type" => "A"}) if record_types.include?("A") || record_types.include?("ANY")

        elsif resource.type == Dnsruby::Types::AAAA
          _create_entity(entity_type, { "name" => "#{resource.rdata}", "parsed_record_type" => "AAAA"}) if record_types.include?("AAAA") || record_types.include?("ANY")

        elsif resource.type == Dnsruby::Types::CNAME
          _create_entity(entity_type, { "name" => "#{resource.rdata}", "parsed_record_type" => "CNAME"}) if record_types.include?("CNAME") || record_types.include?("ANY")

        elsif resource.type == Dnsruby::Types::TXT
          if record_types.include?("TXT") || record_types.include?("ANY")

            _create_entity("Info", { "name" => "TXT record for #{resource.name}", "data" => "#{resource.rdata}"})

            "#{resource.rdata}".split(" ").each do |x|

              _create_entity(entity_type, "name" => x.split(":").last ) if x =~ /^include:/

              # an ip:xxx entry could be a netblock, an ip or a dnsrecord. messy.
            if x =~ /^ip/
              y = x.split(":").last
              if y.include? "/"
                _create_entity("NetBlock", "name" => y )
              elsif y.is_ip_address?
                _create_entity("IpAddress", "name" => y )
              else
                _create_entity("DnsRecord", "name" => y )
              end
            end
          end
        else
          _create_entity("Info", { "name" => "#{resource.type} Record for #{name}", "type" => "#{resource.type}", "data" => "#{resource.rdata}" }) if  record_types.include?("ANY")
        end

      end # end if

    end # end result.answer.map

    rescue Exception => e
      @task_result.logger.log_error "Hit exception: #{e}"
    end

  end

end
end
