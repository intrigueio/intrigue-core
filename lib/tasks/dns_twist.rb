module Intrigue
module Task
class DnsMorph < BaseTask

  def self.metadata
    {
      :name => "dns_twist",
      :pretty_name => "DNS Twist",
      :authors => ["elceef", "Anas Ben Salah"],
      :description => "Uses the excellent DNSTWIST by @elceef to find permuted domains",
      :type => "discovery",
      :references => ["https://github.com/elceef/dnstwist"],
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
    _log "Starting DNSTWIST on #{domain_name}"
    command_string = "sudo docker run elceef/dnstwist -r -f json #{domain_name}"
    json_output = _unsafe_system command_string
    _log "DNSTWIST finished on #{domain_name}!"

    # parse output
    #begin
    output = JSON.parse(json_output)
    puts output
    #puts output

  end # end run

end
end
end
