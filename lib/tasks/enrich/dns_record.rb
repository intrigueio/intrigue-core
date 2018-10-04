module Intrigue
module Task
class EnrichDnsRecord < BaseTask

  include Intrigue::Task::Dns

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

    # Do a lookup and keep track of all aliases
    results = resolve(lookup_name)
    _create_aliases(results)

    # Create new entities if we found vhosts / aliases
    _create_vhost_entities(lookup_name)

    _set_entity_detail("resolutions", collect_resolutions(results) )

    _set_entity_detail("soa_record", collect_soa_details(lookup_name))

    # grab any / all MX records (useful to see who accepts mail)
    _set_entity_detail("mx_records", collect_mx_records(lookup_name))

    # collect TXT records (useful for random things)
    _set_entity_detail("txt_records", collect_txt_records(lookup_name))

    # grab any / all SPF records (useful to see who accepts mail)
    _set_entity_detail("spf_record", collect_spf_details(lookup_name))

    # handy in general, do this for all SOA records
    if _get_entity_detail("soa_record")
      _log_good "Creating domain: #{_get_entity_name}"
      _create_entity "Domain", "name" => _get_entity_name
    else # check if tld
      # one at a time, check all known TLDs and see what we have left. if we
      # have a single string, this is TLD and we should create it as a domain
      File.open("#{$intrigue_basedir}/data/public_suffix_list.clean.txt").read.each_line do |l|
        entity_name = "#{_get_entity_name}".downcase
        suffix = "#{l.chomp}".downcase
        # determine if there's a match with this suffix
        if entity_name =~ /#{suffix}$/
          # if so, remove it
          remove_length = ".#{suffix}".length
          x = entity_name[0..-remove_length]
          if x.split(".").length == 1
            _log "Yahtzee, TLD: #{entity_name}!"
            e = _create_entity "Domain", "name" => "#{entity_name}"
          else
            _log "Not a TLD: #{x}"
          end
        end
      end;nil
    end

  end

  private

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


end
end
end
