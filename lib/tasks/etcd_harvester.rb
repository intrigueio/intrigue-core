module Intrigue
module Task
class EtcdHarvester < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "etcd_harvester",
      :pretty_name => "Etcd Harvest",
      :authors => ["jcran"],
      :description => "Grab keys from etcd daemon.",
      :references => [
        "https://github.com/coreos/etcd/blob/master/Documentation/op-guide/container.md",
        "https://elweb.co/the-security-footgun-in-etcd/",
        "https://twitter.com/bad_packets/status/975502158652035072"
      ],
      :type => "enrichment",
      :passive => false,
      :allowed_types => ["Uri","IpAddress"],
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

    entity = _get_entity_name

    _log_good "Harvesting Etcd for #{entity}"
    if @entity.kind_of? Intrigue::Entity::IpAddress
      json = JSON.parse http_get_body("http://#{entity}:2379/v2/keys/?recursive=true")
    elsif @entity.kind_of? Intrigue::Entity::Uri
      json = http_get_body JSON.parse(entity)
    end

    _log_good "Got: #{JSON.pretty_generate json}"
    @entity.set_detail("etcd_keys",JSON.generate(json))
  end

end
end
end
