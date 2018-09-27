module Intrigue
module Task
class WhoisLookup < BaseTask

  include Intrigue::Task::Whois

  def self.metadata
    {
      :name => "whois_lookup",
      :pretty_name => "Whois Lookup",
      :authors => ["jcran"],
      :description => "Perform a whois lookup for a given entity",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord","IpAddress","NetBlock","Organization"],
      :example_entities => [
        {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}},
        {"type" => "IpAddress", "details" => {"name" => "192.0.78.13"}},
      ],
      :allowed_options => [
        {:name => "create_contacts", :regex => "boolean", :default => true },
        {:name => "create_nameservers", :regex => "boolean", :default => true }
      ],
      :created_types => ["DnsRecord", "EmailAddress", "NetBlock", "Person"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    opt_create_nameservers = _get_option "create_nameservers"
    opt_create_contacts = _get_option "create_contacts"

    # take the first ip if we have a netblock
    if _get_entity_type_string == "NetBlock"
      lookup_string = _get_entity_name.split("/").first
    else
      lookup_string = _get_entity_name
    end

    # do the lookup via normal whois - works for all entities except org
    unless _get_entity_type_string == "Organization"
      out = whois lookup_string
    else # in org's case, just start empty
      out = {}
    end

    unless out
      _log_error "Unable to query, failing..."
      return nil
    end

    # RIR handling
    if lookup_string.is_ip_address?

      if out["whois_full_text"] =~ /RIPE/
        out = whois_regional "RIPE", lookup_string, out
      else
        out = whois_regional "ARIN", lookup_string, out
      end

      # we'll get a standardized hash back that includes a name etc
      _create_entity "NetBlock", out

    else # Normal Domain, add to the domain's data

      if _get_entity_type_string == "Organization"

        resp = whois_query_arin_org lookup_string

        resp.each do |nb|
          _create_entity "NetBlock", nb
        end

      elsif _get_entity_type_string == "DnsRecord"

        if opt_create_nameservers
          out["nameservers"].each do |n|
            _create_entity("DnsRecord",{"name" => "#{n}"})
          end
        end

        if opt_create_contacts
          out["contacts"].each do |c|
            _log "Creating person/email from contact: #{c}"
            _create_entity("Person", {"name" => c["name"]})
            _create_entity("EmailAddress", {"name" => c["email"]})
          end
        end

        _set_entity_detail("whois_full_text", out["whois_full_text"])
        _set_entity_detail("nameservers", out["nameservers"])
        _set_entity_detail("contacts", out["contacts"])

      else
        _log_error "Unknown entity type, failing"
      end

    end
  end


end
end
end
