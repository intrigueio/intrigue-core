module Intrigue
class ExampleTask < BaseTask

  def self.metadata
    {
      :name => "example",
      :pretty_name => "Example",
      :authors => ["jcran"],
      :description => "This is an example task. It returns a randomly-generated host.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [
        {"type" => "String", "attributes" => {"name" => "intrigue"}}
      ],
      :allowed_options => [
        {:name => "unused_option", :type => "Integer", :regex=> "integer", :default => 100 },
        {:name => "count", :type => "Integer", :regex=> "integer", :default => 10 },
        {:name => "sleep", :type => "Integer", :regex=> "integer", :default => 0 }
      ],
      :created_types => ["IpAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    if (_get_option("sleep") < 0)
      _log_error "Invalid option: sleep"
      return
    end

    if (_get_option("count") < 0)
      _log_error "Invalid option: count"
      return
    end

    # Sleep if this option was supplied
    sleep(_get_option("sleep"))

    # Generate a number of hosts based on the user option
    _get_option("count").times do

      #
      # Generate a fake IP address
      #
      ip_address = "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
      _log "Randomly generated an IP address: #{ip_address}"

      #
      # Create & return the entity
      #
      _create_entity("IpAddress", {"name" => ip_address })
    end

  end

end
end
