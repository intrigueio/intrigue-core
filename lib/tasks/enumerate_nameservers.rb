
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

    unless out 
      _log "Empty results!"
      return
    end
      

    out.each do |whois_info|

      _set_entity_detail("whois_full_text", whois_info["whois_full_text"])
      _set_entity_detail("nameservers", whois_info["nameservers"])
      _set_entity_detail("contacts", whois_info["contacts"])

      if whois_info["nameservers"] && !whois_info["nameservers"].empty?
        whois_info["nameservers"].compact.uniq.each do |n|
          # Create a nameserver object
          _create_entity "Nameserver", "name" => n
        end
      end

      ###
      ### TODO ... create contacts here
      ###

    end

  end

end
end
end

