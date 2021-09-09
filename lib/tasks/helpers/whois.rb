require_relative 'web'

module Intrigue
module Task
module Whois

  include Intrigue::Task::Web

  def whois(lookup_string)

    out = []
    tries = 0
    max_tries = 3
    answer = nil 

    until answer || tries > max_tries
      
      begin
        tries +=1 
        whois = ::Whois::Client.new(:timeout => 20)
        answer = whois.lookup(lookup_string)
      
      rescue ::Whois::ResponseIsThrottled => e
        sleep_seconds = rand(20)
        _log_error "Unable to query #{lookup_string}, response throttled, trying again in #{sleep_seconds} secs."
        sleep sleep_seconds
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
    end

    unless answer
      _log_error "No answer, failing"
      return nil
    end

    # grab the parser so we can get specific fields
    parser = answer.parser

    # store whois text so we can get to the right RIR
    whois_text = "#{answer.content}".force_encoding('ISO-8859-1').sanitize_unicode
    
    ###
    ### Note that we need to handle the potential for multiple ranges here, since a 
    ### RIPE range can be split into many CIDRs
    ###
    hash = {}

    if lookup_string.is_ip_address?

      out = []
      # Handle this at the regional internet registry level
      if whois_text.match(/RIPE/)
        _log "Querying RIPE"
        out.concat _whois_query_ripe_ip(lookup_string) # concat an array
      
      elsif whois_text.match(/APNIC/)
        _log "using RDAP to query APNIC"
        out.concat _rdap_ip_lookup(lookup_string) # concat an array
        
      elsif whois_text.match(/whois.lacnic.net/) || whois_text.match(/cert\@cert\.br/)
        _log "using RDAP to query LACNIC"
        out.concat _rdap_ip_lookup(lookup_string) # concat an array
        
      elsif whois_text.match(/AFRINIC/)
        _log "using RDAP to query AFRINIC"
        out.concat _rdap_ip_lookup(lookup_string) # concat an array

      else # Default to ARIN
        out << _whois_query_arin_ip(lookup_string) # add our hash to the array

      end

    else
      hash = {}
      hash["contacts"] = _parse_contacts(parser)
      hash["nameservers"] = _parse_nameservers(parser)
      out << hash
    end

    # add in whois text for all 
    out.each do |hash|
      hash = {} unless hash 
      hash["whois_full_text"] = whois_text
    end

  out # NOTE THAT THIS IS AN ARRAY
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
      _notify "Got invalid JSON for RDAP lookup on #{ip_address}"
      return []
    end

    unless json
      _notify "Got empty JSON for RDAP lookup on #{ip_address}"
      return [] 
    end

    type = "#{json["type"]}"

    if json["links"]
      description = "Queried via RDAP: #{json["links"].first["value"]}"
    end

    # This is just terrible. I am ashamed.
    start_address = json["startAddress"]
    end_address = json["endAddress"]

    # handle the case of multiple cidrs 
    if json["cidr0_cidrs"]
      out = []
      json["cidr0_cidrs"].each do |c|
        start_address = c["v4prefix"]
        cidr_length = c["length"]
        out << {
          "name" => "#{start_address}/#{cidr_length}",
          "start_address" => "#{start_address}",
          #"end_address" => "#{end_address}",
          "cidr" => "#{cidr_length}",
          "description" => "#{description}",
          "block_type" => "#{type}",
          "extended_rdap" => json
        }
      end

    else # do something sane
      cidr_length = "#{json["handle"]}".split("/").last

      # return a standard set of info
      out = [{
        "name" => "#{start_address}/#{cidr_length}",
        "start_address" => "#{start_address}",
        "end_address" => "#{end_address}",
        "cidr" => "#{cidr_length}",
        "description" => "#{description}",
        "block_type" => "#{type}",
        "extended_rdap" => json
      }]

    end

  out
  end


  # returns a hash that can create a netblock
  def _whois_query_ripe_ip(lookup_string,out=[])

    if lookup_string.match(/:/)
      ripe_uri = "https://stat.ripe.net/data/address-space-hierarchy/data.json?resource=#{lookup_string}/64"
    else
      ripe_uri = "https://stat.ripe.net/data/address-space-hierarchy/data.json?resource=#{lookup_string}/32"
    end

    json = JSON.parse(http_get_body(ripe_uri))
    if json && json["data"]
      data = json["data"]
    else
      data = {}
    end

    # parse out ranges
    if data["last_updated"]
      range = data["last_updated"].first["ip_space"]
      start_address = range.split("/").first.strip
      cidr = range.split("/").last.strip
      exact = false
    elsif !data["exact"].empty? && data["more_specific"].empty?  # RIPE
      range = data["exact"].first["inetnum"]
      start_address = range.split("-").first.strip
      end_address = range.split("-").last.strip
      netname = data["exact"].first["netname"]
      org = data["exact"].first["org"]
      exact = true 
    elsif !data["more_specific"].empty? && data["more_specific"].first["inetnum"] # IPv4 CASE
      range = data["more_specific"].first["inetnum"]
      start_address = range.split("-").first.strip
      end_address = range.split("-").last.strip
      netname = data["more_specific"].first["netname"]
      org = data["more_specific"].first["org"]
      exact = false
    elsif !data["more_specific"].empty? && data["more_specific"].first["inet6num"] # IPV6 CASE!
      range = data["more_specific"].first["inet6num"]
      start_address = range.split("/").first.strip
      cidr = range.split("/").last.strip
      netname = data["more_specific"].first["netname"]
      org = data["more_specific"].first["org"]
      exact = false
    elsif !data["less_specific"].empty? && data["less_specific"].first["inetnum"] # IPv4 CASE
      range = data["less_specific"].first["inetnum"]
      start_address = range.split("-").first.strip
      end_address = range.split("-").last.strip
      netname = data["less_specific"].first["netname"]
      org = data["less_specific"].first["org"]
      exact = false
    elsif !data["less_specific"].empty? && data["less_specific"].first["inet6num"] # IPV6 CASE!
      range = data["less_specific"].first["inet6num"]
      start_address = range.split("/").first.strip
      cidr = range.split("/").last.strip
      netname = data["less_specific"].first["netname"]
      org = data["less_specific"].first["org"]
      exact = false
    else
      _log_error "Unknown response, unable to continue"
      _log "Got: #{data}"
      return []
    end

    # parse out description
    begin

      #more_specific_hash = data["more_specific"]
      #less_specific_hash = data["less_specific"]
      #if more_specific_hash
      #  if more_specific_hash && more_specific_hash["descr"]
      #    _log "more specific hash: #{more_specific_hash}"
      #    description = more_specific_hash.first["descr"]
      ##  end
      #elsif less_specific_hash
      #  if less_specific_hash && less_specific_hash["descr"]
      #    _log "less_specific_hash: #{less_specific_hash}"
      #    description = less_specific_hash.first["descr"]
      #  end
      #end

      # convert the range to cidr format
      unless cidr 
        cidrs = range_to_cidrs(start_address, end_address).map{|x| x.to_cidr }
      end

      out = []
      (cidrs || [cidr]).each do  |x|
        # merge in our details
        out << {
          "exact" => exact,
          "name" => "#{start_address}/#{x.split("/").last}",
          "start_address" => "#{start_address}",
          "end_address" => "#{end_address}",
          # note that this will already be the length if pulled from above, 
          # split is harmless 
          "cidr" => "#{x.split("/").last}", 
          "rir" => "RIPE",
          #"description" => "#{description}".sanitize_unicode,
          "organization_reference" => "#{netname}".sanitize_unicode,
          "organization_name" => "#{org}".sanitize_unicode,
          "provider" => "#{org}".sanitize_unicode,
          "multiple_cidrs" => (cidrs || []).count > 1
        }
      end

    rescue TypeError => e
      _log_error "PARSING ERROR! Unable to get RIPE details for #{lookup_string} #{e}"
    end

  out
  end


  # returns a hash that can create a netblock
  def _whois_query_arin_ip(lookup_string,out={})
    begin
      
      # EX: http://whois.arin.net/rest/ip/72.30.35.9.json
      json = JSON.parse http_get_body("http://whois.arin.net/rest/ip/#{lookup_string}.json")
      return nil unless json

      # verify we have something usable
      doc = json["net"]
      return nil unless doc

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
      contacts = []
      parser.contacts.each do |contact|\
        contacts << {
          "name" => "#{contact.name}",
          "email" => "#{contact.email}"
        }
      end
    rescue ::Whois::AttributeNotImplemented => e
      _log_error "Unable to parse attribute: #{e}"
    rescue ::Whois::ParserError => e
      _log_error "Unable to parse attribute: #{e}"
    rescue ::Whois::ResponseIsThrottled
      _log_error "We're too fast and being throttled"
    end
  contacts
  end

  def _parse_nameservers(parser, hash={})
    # handle nameservers
    nameservers = []
    begin
      _log "Parsing: #{parser.nameservers.count} nameservers."
      parser.nameservers.each do |nameserver|
        _log "Parsed nameserver: #{nameserver}"
        nameservers << "#{nameserver}"
      end
    rescue ::Whois::AttributeNotImplemented => e
      _log_error "Unable to parse attribute: #{e}"
    rescue ::Whois::ParserError => e
      _log_error "Unable to parse attribute: #{e}"
    rescue ::Whois::ResponseIsThrottled => e
      _log_error "Unable to parse attribute: #{e}"
    end
  nameservers
  end


end
end
end
