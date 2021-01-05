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

    resources = collect_mx_records _get_entity_name

    resources.each do |r|
      create_dns_entity_from_string r["name"]
    end

  end

end
end
end
