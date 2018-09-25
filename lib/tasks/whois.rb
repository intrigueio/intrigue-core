module Intrigue
module Task
class Whois < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "whois",
      :pretty_name => "Whois",
      :authors => ["jcran"],
      :description => "Perform a whois lookup for a given entity",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord","IpAddress","NetBlock"],
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

    ###
    ### Whois::Client can't handle the netblock format, so
    ### select the first ip if we're given a netblock
    ###
    if @entity.kind_of? Intrigue::Entity::NetBlock
      lookup_string = _get_entity_name.split("/").first
    else # otherwise, use what we're given
      lookup_string = _get_entity_name

    end

    # do the lookup via normal whois
    out = whois lookup_string

    unless out
      _log_error "Unable to query domain, returning..."
      return nil
    end

    # RIR handling
    if lookup_string.is_ip_address?
      if out["whois_full_text"] =~ /RIPE/
        response_hash = whois_query_ripe_ip(lookup_string, out)
      else
        response_hash = whois_query_arin_ip(lookup_string, out)
      end

      # we'll get a standardized hash back that includes a name etc
      _create_entity "NetBlock", response_hash

    else # Normal Domain, add to the domain's data

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
    end

  end

  def whois(lookup_string)

    begin
      whois = ::Whois::Client.new(:timeout => 30)
      answer = whois.lookup(lookup_string)
    rescue ::Whois::ResponseIsThrottled => e
      _log_error "Unable to query whois: #{e}"
    rescue ::Whois::ConnectionError => e
      _log_error "Unable to query whois: #{e}"
    rescue ::Whois::ServerNotFound => e
      _log_error "Unable to query whois: #{e}"
    rescue Errno::ECONNREFUSED => e
      _log_error "Unable to query whois: #{e}"
    rescue Timeout::Error => e
      _log_error "Unable to query whois: #{e}"
    end

    unless answer
      _log_error "No answer"
      return nil
    end

    # grab the parser so we can get specific fields
    parser = answer.parser

    out = {}
    out["whois_full_text"] = "#{answer.content}".force_encoding('ISO-8859-1').sanitize_unicode

    _parse_nameservers(parser,out)
    _parse_contacts(parser,out)

  out
  end

  def _parse_contacts(parser,hash)
    # handle domain contacts
    begin
      _log "Parsing: #{parser.contacts.count} contacts."
      hash["contacts"] = []
      parser.contacts.each do |contact|

        hash["contacts"] << {
          "name" => "#{contact.name}",
          "email" => "#{contact.email}"
        }

      end
    rescue ::Whois::AttributeNotImplemented => e
      _log_error "Unable to parse attribute: #{e}"
    end
  hash
  end

  def _parse_nameservers(parser, hash)
    # handle nameservers
    begin
      _log "Parsing: #{parser.nameservers.count} nameservers."
      hash["nameservers"] = []
      parser.nameservers.each do |nameserver|
        _log "Parsed nameserver: #{nameserver}"
        hash["nameservers"] << "#{nameserver}"
      end
    rescue ::Whois::AttributeNotImplemented => e
      _log_error "Unable to parse attribute: #{e}"
    end
  hash
  end

  def whois_query_arin_ip(lookup_string,out={})
    begin
      # EX: http://whois.arin.net/rest/ip/72.30.35.9.json
      json = JSON.parse http_get_body("http://whois.arin.net/rest/ip/#{lookup_string}.json")
      doc = json["net"]
      org_ref = doc["orgRef"]["$"]
      org_name = doc["orgRef"]["@name"]
      parent_ref = doc["parentNetRef"]
      org_handle = doc["orgRef"]["@handle"]

      handle = doc["handle"]["$"]

      # should be most specific at the top ... TODO verify
      netblock_hash = doc["netBlocks"]
      netblock_data = netblock_hash["netBlock"] # get the subhash

      cidr_length = netblock_data["cidrLength"]["$"]
      start_address = netblock_data["startAddress"]["$"]
      end_address = netblock_data["endAddress"]["$"]
      block_type = netblock_data["type"]["$"]
      description = netblock_data["description"]["$"]

      #
      # Create the hash to return
      #
      out = out.merge({
        "name" => "#{start_address}/#{cidr_length}",
        "start_address" => "#{start_address}",
        "end_address" => "#{end_address}",
        "cidr" => "#{cidr_length}",
        "description" => "#{description}".force_encoding('ISO-8859-1').sanitize_unicode,
        "block_type" => "#{block_type}".sanitize_unicode,
        "handle" => "#{handle}".sanitize_unicode,
        "organization_name" => "#{org_name}".sanitize_unicode,
        "organization_reference" => "#{org_ref}".sanitize_unicode,
        "organization_handle" => "#{org_handle}".sanitize_unicode,
        "parent_reference" => "#{parent_ref}".sanitize_unicode,
        "rir" => "ARIN",
        "provider" => "#{org_name.sanitize_unicode}"
      })

    rescue JSON::ParserError => e
      _log_error "Got an error while parsing: #{e}"
    end

    _log "Got ARIN Hash: #{out}"

  out
  end

  def whois_query_ripe_ip(lookup_string,out={})
    ripe_uri = "https://stat.ripe.net/data/address-space-hierarchy/data.json?resource=#{lookup_string}/32"
    json = JSON.parse(http_get_body(ripe_uri))

    # set entity details
    _log "Got JSON from #{ripe_uri}:"
    _log "#{json}"

    data = json["data"]
    range = data["last_updated"].first["ip_space"]

    # parse out description
    begin
      less_specific_hash = data["less_specific"]
      if less_specific_hash && less_specific_hash.first["descr"]
        _log "less_specific_hash: #{less_specific_hash}"
        description = less_specific_hash.first["descr"]
      end

      # parse out netname
      if less_specific_hash && less_specific_hash.first["netname"]
        netname = less_specific_hash.first["netname"]
      end

      out = out.merge({
        "name" => "#{range}",
        "cidr" => "#{range.split('/').last}",
        "description" => "#{description}".force_encoding('ISO-8859-1').sanitize_unicode,
        "rir" => "RIPE",
        "rir_parsed" => "#{json["data"]["rir"]}",
        "organization_reference" => "#{netname}".sanitize_unicode,
        "organization_name" => "#{description}".sanitize_unicode,
        "provider" =>  "#{description}".force_encoding('ISO-8859-1').sanitize_unicode })

    rescue TypeError => e
      _log_error "PARSING ERROR! Unable to get details from #{less_specific_hash} #{e}"
    end

    _log "Got RIPE Hash: #{out}"

  out
  end

end
end
end
