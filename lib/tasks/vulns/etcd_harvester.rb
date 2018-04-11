module Intrigue
module Task
class EtcdHarvester < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "etcd_harvester",
      :pretty_name => "Etcd Harvester",
      :authors => ["jcran"],
      :identifiers => [{ "cve" =>  false }],
      :description => "Grab keys from etcd daemon.",
      :references => [
        "https://github.com/coreos/etcd/blob/master/Documentation/op-guide/container.md",
        "https://elweb.co/the-security-footgun-in-etcd/",
        "https://twitter.com/bad_packets/status/975502158652035072"
      ],
      :type => "vulnerability_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io:2379/v2/keys/?recursive=true"}}
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Construct the URI
    if @entity.name =~ /\/v2\/keys\/\?recursive=true/
      uri = _get_entity_name
    else
      uri = "#{_get_entity_name}/v2/keys/?recursive=true"
    end


    begin
      # get the response
      _log "Harvesting Etcd for #{uri}"
      response = http_get_body(uri)

      # Make sure we got something sane back
      unless response
        _log_error "Unable to get a response"
        return
      end

      # Parse and print it
      _log "Parsing response from #{uri}"
      hash = JSON.parse response

      # Save it on the entity
      @entity.set_detail("vuln_etcd",true)
      @entity.set_detail("vuln_etcd_output",hash)

    rescue JSON::ParserError => e
      _log_error "unable to parse: #{e}"
    end

  end

end
end
end
