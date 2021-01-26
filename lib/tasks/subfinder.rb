module Intrigue
  module Task
  class Subfinder < BaseTask
  
    def self.metadata
      {
        :name => "subfinder",
        :pretty_name => "Subfinder",
        :authors => ["jcran", "projectdiscovery"],
        :description => "This task uses subfinder to find domains.",
        :references => [],
        :type => "discovery",
        :passive => false,
        :allowed_types => ["Domain"],
        :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
        :allowed_options => [],
        :created_types => [ "DnsRecord", "IpAddress" ]
      }
    end
  
    ## Default method, subclasses must override this
    def run
      super

      domain = _get_entity_name

      command = "subfinder -oJ -silent -d #{domain}"
      _log "Running: #{command}"
      
      out = _unsafe_system(command)

      # handle the no-result case
      unless out 
        _log "No output! returning!"
        return
      end

      # otherwise, create network services 
      lines = out.split("\n")
      _log "Got #{lines.count} subdomains!"
      lines.each do |l|
        j = JSON.parse(l)
        subdomain = j["host"]
        create_dns_entity_from_string(
          subdomain, nil, false, { "subfinder_upstream_source" => j["source"] })
      end

    end
  
  end
  end
  end
  