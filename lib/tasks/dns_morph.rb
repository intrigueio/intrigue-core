module Intrigue
module Task
class DnsMorph < BaseTask

  def self.metadata
    {
      :name => "dns_morph",
      :pretty_name => "DNS Morph",
      :authors => ["netevert", "jcran"],
      :description => "Uses the excellent DNSMORPH by @netevert to find purmuted domains",
      :type => "discovery",
      :references => ["https://github.com/netevert/dnsmorph"],
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [ {"type" => "Domain", "attributes" => {"name" => "intrigue.io"}} ],
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
    command_string = "dnsmorph -d #{domain_name} -json"
    json_output = _unsafe_system command_string
    _log "DNSMORPH finished on #{domain_name}!"

    # parse output
    begin
      output = JSON.parse(json_output)
    rescue JSON::ParserError => e
      _log_error "Unable to parse!"
    end

    # sanity check
    _log_error "No output, failing" and return unless output 

    if _get_option "create_domains"
      output["results"].each do |d|
        
        domain_arguments = { "name" => "#{d["domain"]}" }
        
        # if the option is set, mark this domain unscoped (so we don't try to iterate on it)
        domain_arguments.merge({ "unscoped" => true }) if _get_option("unscope_domains")

        _create_entity "Domain", domain_arguments
      end
    end

    _set_entity_detail "dnsmorph", output["results"]

  end # end run

end
end
end
