require_relative 'web'

module Intrigue
module Task
module Whois

  include Intrigue::Task::Web

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

  def whois_rir_ip(rir, lookup_string, out={})
    if rir == "RIPE"
      response_hash = whois_query_ripe_ip(lookup_string, out)
    elsif rir == "ARIN"
      response_hash = whois_query_arin_ip(lookup_string, out)
    else
      _log_error "Unknown RIR... failing"
    end
  end

  # returns a hash that can create a netblock
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

  # Returns an array of netblocks related to this org
  def whois_query_arin_org(lookup_string,out={})
    begin
      out = []
      search_doc = Nokogiri::XML(http_get_body("http://whois.arin.net/rest/orgs;name=#{URI.escape(lookup_string)}*"));nil
      orgs = search_doc.xpath("//xmlns:orgRef")

      # Goal: for each netblock, create an entity
      orgs.children.each do |org|

        _log_good "Working on #{org.text}"
        net_list_doc = Nokogiri::XML(http_get_body("#{org.text}/nets"))

        begin
          nets = net_list_doc.xpath("//xmlns:netRef")
          nets.children.each do |net_uri|
            _log_good "Net: #{net_uri}" if net_uri

            #page = "https://whois.arin.net/rest/net/NET-64-41-230-0-1.xml"
            page = "#{net_uri}.xml"

            net_doc = Nokogiri::XML(http_get_body(page))
            net_blocks = net_doc.xpath("//xmlns:netBlocks")

            net_blocks.children.each do |n|

              start_address = n.css("startAddress").text
              end_address = n.css("endAddress").text
              description = n.css("description").text
              cidr_length = n.css("cidrLength").text
              type = n.css("type").text

              # Do a regular lookup - important that we get this so we can verify
              # if the block actually belongs to the expected party (via whois_full_text)
              whois_hash = whois start_address

              whois_hash = whois_hash.merge({
                "name" => "#{start_address}/#{cidr_length}",
                "start_address" => "#{start_address}",
                "end_address" => "#{end_address}",
                "cidr" => "#{cidr_length}",
                "description" => "#{description}",
                "block_type" => "#{type}"
              })

              _log_good "Storing netblock: #{whois_hash}"
              out << whois_hash

            end # end netblocks.children
          end # end nets.children

        rescue Nokogiri::XML::XPath::SyntaxError => e
          _log_error " [x] No nets for #{org.text}"
          _log_error "#{e}"
        end

      end # end orgs.children

    rescue Nokogiri::XML::XPath::SyntaxError => e
      _log_error " [x] No orgs!"
    end
  out
  end

  # returns a hash that can create a netblock
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

  private  # helper methods for parsing

  def _parse_contacts(parser,hash={})
    # handle domain contacts
    begin
      _log "Parsing: #{parser.contacts.count} contacts."
      hash["contacts"] = []
      parser.contacts.each do |contact|\
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

  def _parse_nameservers(parser, hash={})
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


end
end
end
