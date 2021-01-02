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
      :allowed_types => ["Domain","DnsRecord","IpAddress","NetBlock","Organization"],
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

      # look up the first address
      lookup_string = _get_entity_name.split("/").first
      out = whois_safe lookup_string
      return nil if out.empty?

      # and edit this netblock
      _log_good "Setting entity details (NOTE, only using first range from whois)!"
      wh = out.first
      get_and_set_entity_details wh

    elsif _get_entity_type_string == "IpAddress"
      
      # TODO... there might be a way to shortcut so many lookups... 
      # store on the ipaddress? or create earlier
      #  _get_entity_detail "whois_full_text" # return if we have it
            
      out = whois_safe _get_entity_name
      return nil if !out || (out && out.empty?)
    
      out.each do |nb|
        _create_entity "NetBlock", { "name" => nb["name"] } 
      end

    elsif _get_entity_type_string == "Organization"

      # look it up and create all known netblocks
      out = whois_query_arin_org _get_entity_name
      unless out.empty?
        out.each do |nb|
          _create_entity "NetBlock", {"name" => nb["name"]}
        end
      end

    elsif _get_entity_type_string == "DnsRecord" || _get_entity_type_string == "Domain"

      out = whois_safe _get_entity_name
      return nil if out.empty?

      out.each do |wh| 

        if opt_create_nameservers
          wh["nameservers"].each do |n|
            _create_entity("DnsRecord", { "name" => "#{n}" })
          end
        end

        if opt_create_contacts
          wh["contacts"].each do |c|
            _log "Creating person/email from contact: #{c}"
            _create_entity("Person", {"name" => c["name"]})
            _create_entity("EmailAddress", {"name" => c["email"]})
          end
        end

        _set_entity_detail("whois_full_text", wh["whois_full_text"]) unless _get_entity_detail("whois_full_text")
        _set_entity_detail("nameservers", wh["nameservers"]) unless _get_entity_detail("nameservers")
        _set_entity_detail("contacts", wh["contacts"]) unless _get_entity_detail("contacts")
      
      end

    else
      _log_error "Unknown entity type, failing"
    end

  end

  def whois_safe(string)
    out = whois(string)#.merge({"name" => string})

    unless out
      _log_error "unable to query, failing"
    end

  out
  end

end
end
end
