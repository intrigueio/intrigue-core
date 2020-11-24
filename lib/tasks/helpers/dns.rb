module Intrigue
module Task
module Dns

  include Intrigue::Task::Generic
  include Intrigue::Core::System::DnsHelpers # parse_tld, parse_domain_name

  def create_unscoped_dns_entity_from_string(s)
    create_dns_entity_from_string(s, nil, true)
  end

  def create_dns_entity_from_string(s, alias_entity=nil, unscoped=false, more_deets={})
    return nil unless s && s.length > 0

    entity_details = { "name" => s.gsub("domain: ","").gsub("*.","") }
    entity_details.merge!({"unscoped" => true }) if unscoped
    entity_details.merge!(more_deets)

    if s.is_ip_address?
      _create_entity("IpAddress", entity_details, alias_entity)
    else
      
      # clean it up and create 
      entity_details["name"] = "#{s}".strip.gsub(/^\*\./,"").gsub(/\.$/,"")
      if entity_details["name"].split(".").length == 2
        _create_entity "Domain", entity_details, alias_entity
      else 
        _create_entity "DnsRecord", entity_details, alias_entity
      end

    end
  end

  # Check for wildcard DNS
  def check_wildcard(suffix)
    _log "Checking for wildcards on #{suffix}."
    all_discovered_wildcards = []

    # first, check wordpress....
    # www*
    # ww01*
    # web*
    # home*
    # my*
    check_wordpress_list = []
    ["www.doesntexist.#{suffix}","ww01.#{suffix}","web1.#{suffix}","hometeam.#{suffix}","myc.#{suffix}"].each do |d|
      resolved_address = _resolve(d)
      check_wordpress_list << resolved_address
      #unless resolved_address.nil? || all_discovered_wildcards.include?(resolved_address)
      #  all_discovered_wildcards << resolved_address
      #end
    end

    if check_wordpress_list.compact.count == 5
      _log "Looks like a wordpress-connected domain"
      all_discovered_wildcards = check_wordpress_list
    end

    # Now check for wildcards
    10.times do
      random_string = "#{(0...8).map { (65 + rand(26)).chr }.join.downcase}.#{suffix}"

      # do the resolution
      # www.shopping.intrigue.io - 198.105.244.228
      # www.search.intrigue.io - 198.105.254.228
      resolved_address = _resolve(random_string)

      # keep track of it unless we already have it
      unless resolved_address.nil? || all_discovered_wildcards.include?(resolved_address)
        all_discovered_wildcards << resolved_address
      end

    end

    # If that resolved, we know that we're in a wildcard situation.
    #
    # Some domains have a pool of IPs that they'll resolve to, so
    # let's go ahead and test a bunch of different domains to try
    # and collect those IPs
    if all_discovered_wildcards.uniq.count > 1
      _log "Multiple wildcard ips for #{suffix} after resolving these: #{all_discovered_wildcards}."
      _log "Trying to create an exhaustive list."

      # Now we have to test for things that return a block of addresses as a wildcard.
      # we to be adaptive (to a point), so let's keep looking in chuncks until we find
      # no new ones...
      no_new_wildcards = false

      until no_new_wildcards
        _log "Testing #{all_discovered_wildcards.count * 20} new entries..."
        newly_discovered_wildcards = []

        (all_discovered_wildcards.count * 20).times do |x|
          random_string = "#{(0...8).map { (65 + rand(26)).chr }.join.downcase}.#{suffix}"
          resolved_address = _resolve(random_string)

          # keep track of it unless we already have it
          unless resolved_address.nil? || newly_discovered_wildcards.include?(resolved_address)
            newly_discovered_wildcards << resolved_address
          end
        end

        # check if our newly discovered is a subset of all
        if (newly_discovered_wildcards - all_discovered_wildcards).empty?
          _log "Hurray! No new wildcards in #{newly_discovered_wildcards}. Finishing up!"
          no_new_wildcards = true
        else
          _log "Continuing to search, found: #{(newly_discovered_wildcards - all_discovered_wildcards).count} new results."
          all_discovered_wildcards += newly_discovered_wildcards.uniq
        end

        _log "Known wildcard count: #{all_discovered_wildcards.uniq.count}"
        _log "Known wildcards: #{all_discovered_wildcards.uniq}"
      end

    elsif all_discovered_wildcards.uniq.count == 1
      _log "Only a single wildcard ip: #{all_discovered_wildcards.sort.uniq}"
    else
      _log "No wildcard detected! Moving on!"
    end

  all_discovered_wildcards.uniq # if it's not a wildcard, this will be an empty array.
  end

  # convenience method to just send back name
  def resolve_name(lookup_name, lookup_types=nil)
    resolve_names(lookup_name,lookup_types).first
  end

  # convenience method to just send back names
  def resolve_names(lookup_name, lookup_types=nil)

    names = []
    x = resolve(lookup_name, lookup_types)
    x.each {|y| names << y["name"] }

  names.uniq
  end

  def resolve(lookup_name, lookup_types=nil)
    
    resources = []

    # Handle ip lookup (PTR) first
    if lookup_name.is_ip_address?
      
      # TODO... this should return multiple
      begin   
        entry = Resolv.new.getname lookup_name

        return [] unless entry && entry.length > 0

        out = [{
          "name" => entry,
          "lookup_details" => [{
            "request_record" => lookup_name,
            "response_record_type" => "PTR",
            "response_record_data" => entry 
          }]
        }]
      rescue Resolv::ResolvError =>e 
        _log_error "Hit exception: #{e}."
      rescue Errno::ENETUNREACH => e
        _log_error "Hit exception: #{e}. Are you sure you're connected?"
      end

    # Then everything else 
    else

      begin 
        # default types to check 
        lookup_types = [
          Resolv::DNS::Resource::IN::AAAA, 
          Resolv::DNS::Resource::IN::A,
          Resolv::DNS::Resource::IN::CNAME] unless lookup_types

        # lookup each type
        lookup_types.each do |t|
          Resolv::DNS.open() {|dns|
            dns.timeouts = 5
            resources.concat(dns.getresources(lookup_name, t)) 
          }
        end

        # translate results into a ruby hash
        out = resources.map do |r|

          entry = lookup_name
          entry = r.address.to_s if r.respond_to? "address"
          entry = r.name.to_s if r.respond_to? "name"
          entry = r.exchange.to_s if r.respond_to? "exchange"

          record_type = r.class.to_s.split(":").last

          record_data = r.inspect.to_s # default to just dumping the object (gross)
          record_data = r.data.to_s if r.respond_to? "data" # Type257_Class1
          record_data = r.address.to_s if (record_type == "A" || record_type == "AAAA") # && r.respond_to?("name")
          record_data = r.strings.join(",") if record_type == "TXT"
          record_data = {"exchange" => r.exchange.to_s, "priority" => r.preference} if record_type == "MX"
          record_data = r.name.to_s if record_type == "CNAME"
          record_data = r.name.to_s if record_type == "NS"
          record_data = { "cpu" => r.cpu.to_s, "os" => r.os.to_s } if record_type == "HINFO"
          record_data = {
              "mname" => r.mname.to_s, 
              "rname"=> r.rname.to_s, 
              "serial" => r.serial } if record_type == "SOA"

          # sanitize and return
          {
            "name" => entry.sanitize_unicode,
            "ttl" => r.ttl,
            "lookup_details" => [{
              "request_record" => lookup_name.sanitize_unicode,
              "response_record_type" => record_type,
              "response_record_data" => record_data.sanitize_unicode 
            }]
          }
        end

      rescue Resolv::ResolvError => e 
        _log_error "Hit exception: #{e}."
      rescue Errno::ENETUNREACH => e
        _log_error "Hit exception: #{e}. Are you sure you're connected?"
      end
    end 

  out || []
  end

  def resolve_old(lookup_name, lookup_types=nil)
    lookup_types = [Dnsruby::Types::AAAA, Dnsruby::Types::A, Dnsruby::Types::CNAME, Dnsruby::Types::PTR] unless lookup_types

    config = {
      :search => [],
      :retry_times => 3,
      :retry_delay => 3,
      :packet_timeout => 30,
      :query_timeout => 30
    }

    if _get_system_config("resolvers")
      config[:nameserver] = _get_system_config("resolvers").split(",")
    end

    resolver = Dnsruby::Resolver.new(config)

    results = []
    lookup_types.each do |t|

      begin
        results << resolver.query(lookup_name, t)
      rescue Dnsruby::NXDomain => e
        # silently move on
      rescue IOError => e
        _log_error "Error resolving: #{lookup_name}, error: #{e}"
      rescue Dnsruby::SocketEofResolvError => e
        _log_error "Error resolving: #{lookup_name}, error: #{e}"
      rescue Dnsruby::ServFail => e
        _log_error "Error resolving: #{lookup_name}, error: #{e}"
      rescue Dnsruby::ResolvTimeout => e
        _log_error "Error resolving: #{lookup_name}, error: #{e}"
      end
    end

    return [] if results.empty?

    begin

      # For each of the found addresses
      resources = []
      results.each do |result|

        # Let us know if we got an empty result
        next if result.answer.empty?

        result.answer.map do |resource|

          #next if resource.type == Dnsruby::Types::NS

          resources << {
            "name" => resource.address.to_s,
            "lookup_details" => [{
              "request_record" => lookup_name,
              "response_record_type" => resource.type.to_s,
              "response_record_data" => resource.rdata.to_s,
              "nameservers" => resolver.config.nameserver }]} if resource.respond_to? :address

          resources << {
            "name" => resource.domainname.to_s.downcase,
            "lookup_details" => [{
              "request_record" => lookup_name,
              "response_record_type" => resource.type.to_s,
              "response_record_data" => resource.rdata,
              "nameservers" => resolver.config.nameserver }]} if resource.respond_to? :domainname

          resources << { # always
            "name" => resource.name.to_s.downcase,
            "lookup_details" => [{
              "request_record" => lookup_name,
              "response_record_type" => resource.type.to_s,
              "response_record_data" => resource.rdata,
              "nameservers" => resolver.config.nameserver }]}

        end # end result.answer
      end
    rescue Dnsruby::SocketEofResolvError => e
      _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
    rescue Dnsruby::ServFail => e
      _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
    rescue Dnsruby::ResolvTimeout => e
      _log_error "Unable to resolve: #{lookup_name}, timed out: #{e}"
    rescue Errno::ENETUNREACH => e
      _log_error "Hit exception: #{e}. Are you sure you're connected?"
    end

  resources || []
  end

  def collect_ns_details(lookup_name)
    _log "Collecting NS records"
    response = resolve(lookup_name, [Resolv::DNS::Resource::IN::NS])
    return [] unless response && !response.empty?

    ns_records = []
    response.each do |r|
      r["lookup_details"].each do |record|
        next unless record["response_record_type"] == "NS"
        ns_records << record["response_record_data"]
      end
    end
    
  ns_records
  end


    # https://support.dnsimple.com/articles/soa-record/
    # [0] primary name server
    # [1] responsible party for the domain
    # [2] timestamp that changes whenever you update your domain
    # [3] number of seconds before the zone should be refreshed
    # [4] number of seconds before a failed refresh should be retried
    # [5] upper limit in seconds before a zone is considered no longer authoritative
    # [6] negative result TTL
  def collect_soa_details(lookup_name)
    _log "Checking start of authority"
    response = resolve(lookup_name, [Resolv::DNS::Resource::IN::SOA])
    return nil unless response && !response.empty?

    data = response.first["lookup_details"].first["response_record_data"]

    { "primary_name_server" => "#{data["mname"]}",
      "responsible_party" => "#{data["rname"]}",
      "serial" => data["serial"] }
  end

  def collect_mx_records(lookup_name)
    _log "Collecting MX records"
    response = resolve(lookup_name, [Resolv::DNS::Resource::IN::MX])
    return [] unless response && !response.empty?

    mx_records = []
    response.each do |r|
      r["lookup_details"].each do |record|
        next unless record["response_record_type"] == "MX"
        mx_records << {
          "priority" => record["response_record_data"]["priority"],
          "host" => "#{record["response_record_data"]["exchange"]}" }
      end
    end

  mx_records
  end

  def collect_spf_details(lookup_name)
    _log "Collecting SPF records"
    response = resolve(lookup_name, [Resolv::DNS::Resource::IN::TXT])
    return [] unless response && !response.empty?

    spf_records = []
    response.each do |r|
      r["lookup_details"].each do |record|
        next unless record["response_record_type"] == "TXT"
        next unless record["response_record_data"] =~ /spf/i
        spf_records << record["response_record_data"]
      end
    end
    
  spf_records
  end

  def collect_txt_records(lookup_name)
    _log "Collecting TXT records"
    txt_records = []
    5.times do 
      response = resolve(lookup_name, [Resolv::DNS::Resource::IN::TXT])
      return [] unless response && !response.empty?

      response.each do |r|
        r["lookup_details"].each do |record|
          next unless record["response_record_type"] == "TXT"
          txt_records << record["response_record_data"]
        end
      end
    end
  txt_records.flatten.uniq
  end

  def collect_resolutions(results)
    ####
    ### Set details for this entity
    ####
    dns_entries = []
    results.each do |result|

      # skip anything without a lookup
      next unless result["lookup_details"]

      # Clean up the response and make it serializable
      xtype = result["lookup_details"].first["response_record_type"].to_s.sanitize_unicode
      lookup_details = result["lookup_details"].first["response_record_data"]
      
      _log "Sanitizing String or Array"
      xdata = result["lookup_details"].first["response_record_data"].to_s.sanitize_unicode

      dns_entries << { "response_data" => xdata, "response_type" => xtype }
    end

  dns_entries.uniq
  end

  def check_and_create_unscoped_domain(lookup_name)

    # get the domain's tld
    domain_name = parse_domain_name(lookup_name)

    # we're already a tld, or we are one step down.... create as a domain
    if domain_name
      
      # since we are creating an identical domain, send up the details
      e = _create_entity "Domain", {
        #"unscoped" => true,
        "name" => "#{domain_name}",
        "resolutions" => _get_entity_detail("resolutions"),
        "soa_record" => _get_entity_detail("soa_record"),
        "mx_records" => _get_entity_detail("mx_records"),
        "txt_records" => _get_entity_detail("txt_records"),
        "spf_record" => _get_entity_detail("spf_record")}
    else 
      _log_error "Unable to create a domain from: #{lookup_name}"
    end

  end

  # this method is used to test a string 
  # for whether it it matches the pattern of an 
  # RFC1918 (internal) address
  def match_rfc1918_address?(range_or_ip)
    return true if ( 
      range_or_ip =~ /^172\.16\.\d\.\d/
      range_or_ip =~ /^192\.168\.\d\.\d/
      range_or_ip =~ /^10\.\d\.\d\.\d/)
  false 
  end

end
end
end
