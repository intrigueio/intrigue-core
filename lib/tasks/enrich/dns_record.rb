module Intrigue
module Task
class EnrichDnsRecord < BaseTask

  def self.metadata
    {
      :name => "enrich/dns_record",
      :pretty_name => "Enrich DnsRecord",
      :authors => ["jcran"],
      :description => "Fills in details for a DnsRecord",
      :references => [],
      :allowed_types => ["DnsRecord"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [
        {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord","IpAddress"]
    }
  end

  def run
    super

    lookup_name = _get_entity_name

    _set_entity_detail("soa_record", _collect_soa_details(lookup_name))

    # Do a lookup and keep track of all aliases
    results = resolve(lookup_name)
    _create_aliases(results)

    _set_entity_detail("resolutions", _collect_resolutions(results) )

    # Create new entities if we found vhosts / aliases
    _create_vhost_entities(lookup_name)

    # grab any / all MX records (useful to see who accepts mail)
    _set_entity_detail("mx_records", _collect_mx_records(lookup_name))

    # collect TXT records (useful for random things)
    _set_entity_detail("txt_records", _collect_txt_records(lookup_name))

    # grab any / all SPF records (useful to see who accepts mail)
    #_set_entity_detail("spf", _collect_spf_details(lookup_name))

    # handy in general, do this for all SOA records
    if _get_entity_detail("soa_record")
      out = _collect_whois_data(lookup_name)
      if out
        _set_entity_detail("whois_full_text", out["whois_full_text"])
        _set_entity_detail("nameservers", out["nameservers"])
        _set_entity_detail("contacts", out["contacts"])
      else
        _log_error "Unable to gather whois information, writing nils"
        _set_entity_detail("whois_full_text", nil)
        _set_entity_detail("nameservers", nil)
        _set_entity_detail("contacts", nil)
      end
    end

  end

  private

    def _collect_soa_details(lookup_name)
      _log "Checking start of authority"
      response = resolve(lookup_name, [Dnsruby::Types::SOA])

      # Check for sanity
      skip = true unless response &&
                         !response.empty? &&
                         response.first["lookup_details"].first["response_record_type"] == "SOA"

      unless skip
        data = response.first["lookup_details"].first["response_record_data"]

        # https://support.dnsimple.com/articles/soa-record/
        # [0] primary name server
        # [1] responsible party for the domain
        # [2] timestamp that changes whenever you update your domain
        # [3] number of seconds before the zone should be refreshed
        # [4] number of seconds before a failed refresh should be retried
        # [5] upper limit in seconds before a zone is considered no longer authoritative
        # [6]  negative result TTL

        soa = {
          "primary_name_server" => "#{data[0]}",
          "responsible_party" => "#{data[1]}",
          "timestamp" => data[2],
          "refresh_after" => data[3],
          "retry_refresh_after" => data[4],
          "nonauthoritative_after" => data[5],
          "retry_fail_after" => data[6]
        }

      else
        soa = false
      end
    soa
    end

    def _collect_mx_records(lookup_name)
      _log "Collecting MX records"
      response = resolve(lookup_name, [Dnsruby::Types::MX])
      skip = true unless response && !response.empty?

      mx_records = []
      unless skip
        response.each do |r|
          r["lookup_details"].each do |record|
            next unless record["response_record_type"] == "MX"
            mx_records << {
              "priority" => record["response_record_data"].first,
              "host" => "#{record["response_record_data"].last}" }
          end
        end
      end

    mx_records
    end

    def _collect_spf_details(spf_record)
      _log "Collecting SPF records"
    end

    def _collect_txt_records(lookup_name)
      _log "Collecting TXT records"
      response = resolve(lookup_name, [Dnsruby::Types::TXT])
      skip = true unless response && !response.empty?

      txt_records = []
      unless skip
        response.each do |r|
          r["lookup_details"].each do |record|
            next unless record["response_record_type"] == "TXT"
            txt_records << record["response_record_data"].first
          end
        end
      end

    txt_records
    end

    def _collect_whois_data(lookup_name)
        _log "Collecting Whois record"
        whois(lookup_name)
    end

    def _create_vhost_entities(lookup_name)
      ### For each associated IpAddress, make sure we create any additional
      ### uris if we already have scan results
      ###
      @entity.aliases.each do |a|
        next unless a.type_string == "IpAddress" #  only ips
        #next if a.hidden # skip hidden
        existing_ports = a.get_detail("ports")
        if existing_ports
          existing_ports.each do |p|
            _create_network_service_entity(a,p["number"],p["protocol"],{})
          end
        end
      end
    end

    def _collect_resolutions(results)
      ####
      ### Set details for this entity
      ####
      dns_entries = []
      results.each do |result|
        # Clean up the dns data
        xtype = result["lookup_details"].first["response_record_type"].to_s.sanitize_unicode
        lookup_details = result["lookup_details"].first["response_record_data"]
        if lookup_details.kind_of?(Dnsruby::IPv4) || lookup_details.kind_of?(Dnsruby::IPv6) || lookup_details.kind_of?(Dnsruby::Name)
          _log "Sanitizing Dnsruby Object"
          xdata = result["lookup_details"].first["response_record_data"].to_s.sanitize_unicode
        else
          _log "Sanitizing String or Array"
          xdata = result["lookup_details"].first["response_record_data"].to_s.sanitize_unicode
        end
        dns_entries << { "response_data" => xdata, "response_type" => xtype }
      end
    dns_entries.uniq
    end

    def _create_aliases(results)
      ####
      ### Create aliased entities
      ####
      results.each do |result|
        _log "Creating entity for... #{result["name"]}"
        if "#{result["name"]}".is_ip_address?
          _create_entity("IpAddress", { "name" => result["name"] }, @entity)
        else
          _create_entity("DnsRecord", { "name" => result["name"] }, @entity)
        end
      end
  end


end
end
end
