module Intrigue
module Task
class DnsMorph < BaseTask

  def self.metadata
    {
      :name => "dns_morph",
      :pretty_name => "DNS Morph",
      :authors => ["netevert", "jcran"],
      :description => "Uses the excellent DNSMORPH by @netevert to find permuted domains",
      :type => "discovery",
      :references => ["https://github.com/netevert/dnsmorph"],
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [ {"type" => "Domain", "details" => {"name" => "intrigue.io"}} ],
      :allowed_options => [
        {:name => "create_domains", :regex => "boolean", :default => false },
        {:name => "unscope_domains", :regex => "boolean", :default => true },
      ],
      :created_types => []
    }
  end

  def run
    super

    domain_name = _get_entity_name

    # task assumes gitrob is in our path and properly configured
    _log "Starting DNSMORPH on #{domain_name}"
    command_string = "dnsmorph -d #{domain_name} -w -r -json"
    json_output = _unsafe_system command_string
    _log "DNSMORPH finished on #{domain_name}!"

    # parse output
    begin
      output = JSON.parse(json_output)
      return unless output && output["results"]

      _log_good "Got #{output["results"].count} permutations!"

      # select only those that resovled
      resolved_domains = output["results"].select{|x| x["a_record"] != "" }

      # now add geolocation & a whois lookup
      resolved_domains = resolved_domains.clone.map do |x|
        
        # make sure it's a string
        ip_address = "#{x["a_record"]}"
        
        geo = geolocate_ip(ip_address)
        x["country_code"] = geo["country_code"] if geo
        
        # use team cymru lookup
        info = Intrigue::Client::Search::Cymru::IPAddress.new.whois(ip_address)
        if info
          x["asn_id"] = info[0] 
          x["asn_name"] = info[5]
          x["allocation_date"] = info[4]
        end

      x
      end

      _log_good "resolved #{resolved_domains.count} domains!" if resolved_domains

    rescue JSON::ParserError => e
      _log_error "Unable to parse!"
    end

    # sanity check
    _log_error "No output, failing" and return unless output 

    if _get_option "create_domains"
      resolved_domains.each do |d|
        
        domain_arguments = { 
          "name" => "#{d["domain"]}".force_encoding("UTF-8") 
        }
        
        # if the option is set, mark this domain unscoped (so we don't try to iterate on it)
        if _get_option("unscope_domains")
          domain_arguments.merge({ "unscoped" => true, "morph" => true  }) 
        end

        _create_entity "Domain", domain_arguments
      end
    end

    # enrich the resolved domains with geo info


    _set_entity_detail "permutations", resolved_domains

  end # end run

end
end
end
