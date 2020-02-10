module Intrigue
module Task
class CreateService < BaseTask

  def self.metadata
    {
      :name => "create_service",
      :pretty_name => "Create Service",
      :authors => ["jcran"],
      :description => "This just creates a network service, like a scanner would.",
      :references => [],
      :type => "creation",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [
        {"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}
      ],
      :allowed_options => [
        {:name => "port", :regex=> "integer", :default => 80 },
        {:name => "protocol", :regex=> "alpha_numeric", :default => "tcp" }
      ],
      :created_types => ["NetworkService","Url"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super
    opt_port = _get_option "port"
    opt_protocol = _get_option "protocol"
    _create_network_service_entity(@entity,opt_port,opt_protocol,{})
  end

end
end
end
