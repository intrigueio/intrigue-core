module Intrigue
class DnsLookupForwardTask < BaseTask

  def self.metadata
    {
      :name => "dns_lookup_forward",
      :pretty_name => "DNS Forward Lookup",
      :authors => ["jcran"],
      :description => "Look up the IP Address of the given hostname. Grab all types of the recor  d.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Host","String"],
      :example_entities => [{"type" => "Host", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" }
      ],
      :created_types => ["Host","Host"]
    }
  end

  def run
    super

    opt_resolver = _get_option "resolver"
    record_types = _get_option "record_types"
    name = _get_entity_name

    begin

      res = Dnsruby::Resolver.new(
        :recurse => "true",
        :query_timeout => 5,
        :nameserver => opt_resolver,
        :search => [])

      result = res.query(name, "ANY")
      _log "Processing: #{result}"

      # Let us know if we got an empty result
      _log_error "Nothing?" if result.answer.empty?

      # For each of the found addresses
      result.answer.map do |resource|
                #next if resource.type == Dnsruby::Types::RRSIG

        # Create the entity
        if resource.type == Dnsruby::Types::SOA
          # Will look something like this:
          # [#<Dnsruby::Name: sopcgm.ual.com.>, #<Dnsruby::Name: ualipconfig.united.com.>, 2011110851, 10800, 3600, 2592000, 600]

          resource.rdata.each do |x|
            if resource.rdata.class == Dnsruby::Name
              _create_entity("Host", { "name" => "#{x}", "parsed_record_type" => "SOA"}) if record_types.include?("SOA") || record_types.include?("ANY")
            end
          end

        elsif ( resource.type == Dnsruby::Types::NS ||
                resource.type == Dnsruby::Types::A ||
                resource.type == Dnsruby::Types::CNAME ||
                resource.type == Dnsruby::Types::MX ||
                resource.type == Dnsruby::Types::AAAA)

          _create_entity("Host", { "name" => "#{resource.rdata}", "parsed_record_type" => "NS"})

        elsif resource.type == Dnsruby::Types::TXT

          _create_entity("Info", { "name" => "TXT record for #{resource.name}", "data" => "#{resource.rdata}"})

          #"#{resource.rdata}".split(" ").each do |x|
            # TODO - we should make parsing of the TXT record optional and default to false
            # it's unlikely that this infrastructure actually belongs to the target
            # _create_entity("Host", "name" => x.split(":").last ) if x =~ /^include:/

            # an ip:xxx entry could be a netblock, an ip or a dnsrecord. messy.
            #if x =~ /^ip/
            #  y = x.split(":").last
            #  if y.include? "/"
            #    _create_entity("NetBlock", "name" => y, "confidence" => 20 )
            #  else
            #    _create_entity("Host", "name" => y, "confidence" => 20 )
            #  end
            #end
          #end

        else
          _create_entity("Info", { "name" => "#{resource.type} Record for #{name}", "type" => "#{resource.type}", "data" => "#{resource.rdata}" }) if  record_types.include?("ANY")
        end

      end # end if

    end # end result.answer.map
    rescue Errno::ENETUNREACH => e
      _log_error "Hit exception: #{e}. Are you sure you're connected?"
    rescue Exception => e
      _log_error "Hit exception: #{e}"
    end

  end

end
end
