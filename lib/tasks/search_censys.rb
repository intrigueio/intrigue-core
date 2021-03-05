module Intrigue
module Task
class SearchCensys < BaseTask

  def self.metadata
    {
      :name => "search_censys",
      :pretty_name => "Search Censys",
      :authors => ["jcran"],
      :description => "This task searches the Censys API for information related to hosts, certificates, and websites",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain", "IpAddress", "NetBlock"],
      :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}},
        {"type" => "IpAddress", "details" => {"name" => "8.8.8. 8"}}
      ],
      :allowed_options => [],
      :created_types => ["DnsRecord", "Domain","IpAddress","SslCertificate"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    begin

      # Make sure the key is set
      uid = _get_task_config "censys_uid"
      secret = _get_task_config "censys_secret"
      
      entity_name = _get_entity_name
      entity_type = _get_entity_type_string

      unless uid && secret
        _log_error "No credentials?"
        return
      end

      # Attach to the censys service & search
      @client = Censys::Api.new(uid,secret)

      if entity_type == "Domain"
        search_certificates_by_domain(entity_name)
      elsif entity_type == "IpAddress"
        search_for_individual_ip(entity_name)
      elsif entity_type == "NetBlock"
        search_by_netblock(entity_name)
      end

    rescue RuntimeError => e
      _log_error "Runtime error: #{e}"
    end

  end # end run()


  ###
  ### Search by netblock and return 
  ###
  def search_by_netblock(netblock)
    results = @client.search_ipv4_index(netblock)
    _log "Got #{results.count} results"
    results.each do |result|
      _create_entity "IpAddress", { "name" => "#{result["ip"]}", "extended_censys" => result }
    end
  end

  def search_certificates_by_domain(domain)
    results = @client.search_certificates_index(domain)
    return unless results 

    _log "Got #{results.count} results"

    results.each do |search_result|
      
      # get the detailed data for this certificate
      full_result = @client.view_certificate(search_result["parse"]["fingerprint_sha256"])

      # Construct the certificate
      subject_dn = full_result["parsed"]["subject"]["common_name"]
      serial = full_result["parsed"]["serial_number"]
      cert_name = "#{subject_dn} (#{serial})"

      # and create it 
      _create_entity "SslCertificate", { "name" => cert_name, "extended_censys" => full_result }

      _log "creating entities from the cert's names"
      
      cert_names = full_result["parsed"]["names"]
      
      # first check to see if this is a universal cert. if so, we can skip
      universal_cert = false
      get_universal_cert_domains.each do |ucn|
        universal_cert = true if cert_names.include? ucn
      end

      if universal_cert
        _log_error "Skipping DNS parsing, we believe this is a universal cert"
      else
        cert_names.each do |n| 
          # creates domain/dns/ip, depending on format of string
          # handles wildcard and basic cleanup of DNS entries
          create_dns_entity_from_string(n)
        end
      end
    end
  end


  def search_for_individual_ip(ip_address)
    ## Grab IPv4 Results
    results = @client.search_ipv4_index("ip:#{ip_address}")
    return unless results 

    results.each do |r|
      next unless r

      if r
        # Go ahead and create the entity, and add all of our censys context
        ip = r["ip"]
        ip_entity = _create_entity "IpAddress", { "name" => "#{ip}", "extended_censys" => r }

        _log "Got protocols: #{r["protocols"]}"

        # Where we can, let's create additional entities from the scan results
        if r["protocols"]
          r["protocols"].each do |p|
            
            _log "Working on #{p}"

            # Pull out the protocol
            port = p.split("/").first.to_i # format is like "80/http"
            _create_network_service_entity(ip_entity, port, "tcp", {
              "extended_censys" => r
            })

          end # iterate through ports
        end # if r["_source"]["protocols"]
      end # if r["_source"]
      
=begin      
      r["certificates"].each do |search_type|
        response = censys.search(entity_name,search_type)
        response["results"].each do |r|
          _log "Got result: #{r}"
          if r["parsed.subject_dn"]
  
            _create_entity "SslCertificate", "name" => r["parsed.subject_dn"], "additional" => r
  
            # Pull out the CN and create a name
            if r["parsed.subject_dn"].kind_of? Array
              r["parsed.subject_dn"].each do |x|
                host = x.split("CN=").last.split(",").first
                _create_entity "IpAddress", "name" => host if host
              end
            else
              _create_entity "IpAddress", "name" => r["parsed.subject_dn"]
            end
           end
        end
      end
=end    
    end # if r

  end


end # end Class
end
end
