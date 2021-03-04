require_relative 'web'

module Intrigue
module Task
module Whois

  include Intrigue::Task::Web

  def whois(lookup_string)

    begin
      whois = ::Whois::Client.new #(:timeout => 60)
      answer = whois.lookup(lookup_string)
    rescue ::Whois::ResponseIsThrottled => e
      _log_error "Unable to query #{lookup_string}, response throttled, trying again in #{sleep_seconds} secs."
      sleep_seconds = rand(60)
      sleep sleep_seconds
      return whois(lookup_string)
    rescue ::Whois::ServerNotSupported => e
      _log_error "Server not supported for #{lookup_string} #{e}"
    rescue ::Whois::NoInterfaceError => e
      _log_error "No interface: #{lookup_string} #{e}"
    rescue ::Whois::WebInterfaceError => e
      _log_error "TLD has no WHOIS Server, go to the web interface: #{lookup_string} #{e}"
    rescue ::Whois::AllocationUnknown => e
      _log_error "Strange. This object is unknown: #{lookup_string} #{e}"
    rescue ::Whois::ConnectionError => e
      _log_error "Unable to query whois, connection error: #{lookup_string} #{e}"
    rescue ::Whois::ServerNotFound => e
      _log_error "Unable to query whois, server not found: #{lookup_string} #{e}"
    rescue Errno::ECONNREFUSED => e
      _log_error "Unable to query whois, connection refused: #{lookup_string} #{e}"
    rescue Timeout::Error => e
      _log_error "Unable to query whois, timed out: #{lookup_string} #{e}"
    end

    unless answer
      _log_error "No answer, failing"
      return nil
    end

    # grab the parser so we can get specific fields
    parser = answer.parser

    out = {}
    out["whois_full_text"] = "#{answer.content}".force_encoding('ISO-8859-1').sanitize_unicode

    if lookup_string.is_ip_address?
      # Handle this at the regional internet registry level
      if out["whois_full_text"] =~ /RIPE/
        out = _whois_query_ripe_ip(lookup_string, out)
      elsif out["whois_full_text"] =~ /APNIC/
        _log "using RDAP to query APNIC"
        rdap_info = _rdap_ip_lookup lookup_string
        out = out.merge(rdap_info)
      elsif out["whois_full_text"] =~ /whois.lacnic.net/ || out["whois_full_text"] =~ /cert\@cert\.br/
        _log "using RDAP to query LACNIC"
        rdap_info = _rdap_ip_lookup lookup_string
        out = out.merge(rdap_info) if rdap_info
      elsif out["whois_full_text"] =~ /AFRINIC/
        _log "using RDAP to query AFRINIC"
        rdap_info = _rdap_ip_lookup lookup_string
        out = out.merge(rdap_info)
      else # Default to ARIN
        out = _whois_query_arin_ip(lookup_string, out)
      end
    else
      _parse_nameservers(parser,out)
      _parse_contacts(parser,out)
    end

  out
  end

  # Returns an array of netblocks related to this org
  def whois_query_arin_org(lookup_string,out={})
    begin
      out = []
      search_doc = Nokogiri::XML(http_get_body("http://whois.arin.net/rest/orgs;name=#{URI.escape(lookup_string)}*"));nil
      orgs = search_doc.xpath("//xmlns:orgRef")
      _log "Got ARIN Response: #{search_doc}"

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
              #whois_hash = whois start_address || {"whois_full_text" => nil}

              whois_hash = {
                "name" => "#{start_address}/#{cidr_length}",
                "start_address" => "#{start_address}",
                "end_address" => "#{end_address}",
                "cidr" => "#{cidr_length}",
                "description" => "#{description}",
                "block_type" => "#{type}"
              }

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

  def range_to_cidrs(lower, upper)
  
    ip_range = IPRanger::IPRange.new(lower, upper)
    cidrs = ip_range.cidrs

  cidrs
  end

  private  # helper methods for parsing

  # use RDAP to query an IP
  def _rdap_ip_lookup(ip_address)
    response = http_get_body "https://rdap.arin.net/registry/ip/#{ip_address}"

    begin
      json = JSON.parse(response)
    rescue JSON::ParserError => e
      return nil
    end

    return nil unless json

    # This is just terrible. I am ashamed.
    start_address = json["startAddress"]
    if response =~ /apnic/
      regex = Regexp.new(/rdap.apnic.net\/ip\/\d.\d.\d.\d\/(\d*)\",/)
      match = response.match(regex)
      cidr_length = match.captures.first.strip if match
    else # do something sane
      cidr_length = "#{json["handle"]}".split("/").last
    end

    if json["links"]
      description = "Queried via RDAP: #{json["links"].first["value"]}"
    end
    
    type = "#{json["type"]}"

    # return a standard set of info
    out = {
      "name" => "#{start_address}/#{cidr_length}",
      "start_address" => "#{start_address}",
      "end_address" => "#{json["endAddress"]}",
      "cidr" => "#{cidr_length}",
      "description" => "#{description}",
      "block_type" => "#{type}",
      "extended_rdap" => response
    }

  out
  end


  # returns a hash that can create a netblock
  def _whois_query_ripe_ip(lookup_string,out={})
    ripe_uri = "https://stat.ripe.net/data/address-space-hierarchy/data.json?resource=#{lookup_string}/32"
    json = JSON.parse(http_get_body(ripe_uri))

    # parse out ranges
    data = json["data"]
    if data["last_updated"]
      range = data["last_updated"].first["ip_space"]
      start_address = range.split("/").first.strip
      cidr = range.split("/").last.strip
      exact = false
    elsif !data["exact"].empty? # RIPE
      range = data["exact"].first["inetnum"]
      start_address = range.split("-").first.strip
      end_address = range.split("-").last.strip
      netname = data["exact"].first["netname"]
      org = data["exact"].first["org"]
      exact = true 
    elsif !data["more_specific"].empty? && data["more_specific"].first["inetnum"] # RIPE
      range = data["more_specific"].first["inetnum"]
      start_address = range.split("-").first.strip
      end_address = range.split("-").last.strip
      netname = data["more_specific"].first["netname"]
      org = data["more_specific"].first["org"]
      exact = false
    elsif !data["less_specific"].empty? && data["less_specific"].first["inetnum"] # RIPE
      range = data["less_specific"].first["inetnum"]
      start_address = range.split("-").first.strip
      end_address = range.split("-").last.strip
      netname = data["less_specific"].first["netname"]
      org = data["less_specific"].first["org"]
      exact = false
    else
      _log_error "Unknown response , unable to continue"
      _log "Got: #{data}"
      return nil
    end

    # parse out description
    begin
      less_specific_hash = data["less_specific"]
      if less_specific_hash && less_specific_hash.first["descr"]
        _log "less_specific_hash: #{less_specific_hash}"
        description = less_specific_hash.first["descr"]
      end

      # convert the range to cidr format
      cidrs = range_to_cidrs(start_address, end_address).map{|x| x.to_cidr}
      raise "Multiple CIDRs available!!!" if cidrs.count > 1

      # merge in our details
      out.merge!({
        "exact" => exact,
        "name" => "#{cidrs.first}",
        "start_address" => "#{start_address}",
        "end_address" => "#{end_address}",
        "cidr" => "#{cidr}",
        "rir" => "RIPE",
        "organization_reference" => "#{netname}".sanitize_unicode,
        "organization_name" => "#{org}".sanitize_unicode,
        "provider" => "#{org}".sanitize_unicode
        })

    rescue TypeError => e
      _log_error "PARSING ERROR! Unable to get details from #{less_specific_hash} #{e}"
    end

  out
  end


  # returns a hash that can create a netblock
  def _whois_query_arin_ip(lookup_string,out={})
    begin
      # EX: http://whois.arin.net/rest/ip/72.30.35.9.json
      json = JSON.parse http_get_body("http://whois.arin.net/rest/ip/#{lookup_string}.json")

      # verify we have something usable
      doc = json["net"]
      return unless doc

      # organization details
      if doc["orgRef"]
        org_ref = doc["orgRef"]["$"]
        org_name = doc["orgRef"]["@name"]
        org_handle = doc["orgRef"]["@handle"]
      end

      parent_ref = doc["parentNetRef"]["$"] if doc["parentNetRef"]
      handle = doc["handle"]["$"]

      # netblock details
      netblocks = doc["netBlocks"]
      netblocks.each do |k,v|
        next unless k == "netBlock" # get the subhash, skip unless we know it

        if v.kind_of? Array
          block_info = v.first
        else # just one
          block_info = v
        end

        cidr_length = block_info["cidrLength"]["$"]
        start_address = block_info["startAddress"]["$"]
        end_address = block_info["endAddress"]["$"]
        block_type = block_info["type"]["$"]
        description = block_info["description"]["$"]

        rir = "TRANSFERRED" if description == "Early Registrations, Transferred to APNIC"

        # Create the hash to return
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
          "rir" => rir || "ARIN",
          "provider" => "#{org_name}".sanitize_unicode
        })
      end

    rescue JSON::ParserError => e
      _log_error "Got an error while parsing: #{e}"
    end

  out
  end


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
    rescue ::Whois::ParserError => e
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
    rescue ::Whois::ParserError => e
      _log_error "Unable to parse attribute: #{e}"
    rescue ::Whois::ResponseIsThrottled => e
      _log_error "Unable to parse attribute: #{e}"
    end
  hash
  end


end
end
end
