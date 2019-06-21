module Intrigue
module Task
class DnsLookupMx < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "dns_lookup_mx",
      :pretty_name => "DNS MX Lookup",
      :authors => ["jcran"],
      :description => "Look up the MX records of the given DNS record.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","DnsRecord"],
      :example_entities => [{"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [ ],
      :created_types => ["IpAddress"]
    }
  end

  def run
    super

    name = _get_entity_name

    begin
      resources = collect_mx_records

      resources.each do |r|
        # Create a DNS record
        if r["name"].is_ip_address?
          _create_entity("IpAddress", { "name" => r["name"]}) 
        else
          _create_entity("DnsRecord", { "name" => r["name"]})
        end
      end

    rescue Errno::ENETUNREACH => e
      _log_error "Hit exception: #{e}. Are you sure you're connected?"
    rescue Exception => e
      _log_error "Hit exception: #{e}"
    end
  end

end
end
end
