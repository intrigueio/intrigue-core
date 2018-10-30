
module Intrigue
module Task
class EnumerateNameservers < BaseTask

  def self.metadata
    {
      :name => "enumerate_nameservers",
      :pretty_name => "Enumerate Nameservers",
      :authors => ["jcran"],
      :description => "Convert an entity to another type",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => ["Nameserver"]
    }
  end

  def run
    super
    lookup_name = _get_entity_name

    # grab whois info
    out = whois(lookup_name)
    if out
      _set_entity_detail("whois_full_text", out["whois_full_text"])
      _set_entity_detail("nameservers", out["nameservers"])
      _set_entity_detail("contacts", out["contacts"])

      if out["nameservers"]
        out["nameservers"].each do |n|

          # Create a nameserver object
          _create_entity "Nameserver", "name" => n

        end
      end

    end

  end

end
end
end

