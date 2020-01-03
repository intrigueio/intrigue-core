module Intrigue
module Task
class Example < BaseTask

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
        {"type" => "String", "details" => {"name" => "intrigue"}}
      ],
      :allowed_options => [
        {:name => "notify", :regex=> "boolean", :default => true },
        {:name => "unused_option", :regex=> "integer", :default => 100 },
        {:name => "count", :regex=> "integer", :default => 3 },
        {:name => "sleep", :regex=> "integer", :default => 0 }
      ],
      :created_types => ["IpAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    name = _get_entity_name
    opt_notify = _get_option("notify")

    # Show some test messages
    _log_good "Got entity: #{name}"
    _log_error "Just printing a test error message"
    _log "Let's keep going!"

    # Show how to get an option and act on it
    if (_get_option("sleep") < 0)
      _log_error "Invalid option: sleep"
      return
    end

    # create an issue
    zone = [1,2,3,4]
    _create_issue({
      name: "Example Issue",
      type: "example",
      severity: 5,
      status: "confirmed",
      description: "just an example.",
      details: { example_attribute: zone }
    })

    # just return if we have bad data
    return unless _get_option("count") > 0

    # Sleep if this option was supplied
    sleep(_get_option("sleep"))

    # Generate a number of hosts based on the user option
    _get_option("count").times do

    # Generate a fake IP address
      ip_address = "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"

      # display a log message
      _log "Randomly generated an IP address: #{ip_address}"

      ###
      # alert if there're any configured notifiers
      ###

      # notifies all notifiers configured with "enabled" and "default"
      _notify "[+] Randomly generated an IP address: #{ip_address}"

      # notifies via all channels of type "slack" and "enabled" set to true
      _notify_type "slack", "[slack] Randomly generated an IP address: #{ip_address}"

      #_log_fatal "Oh no, it's a fatal error!"

      # notifies via a specifically named channel
      _notify_specific "specific_slack", "[specific_slack] Randomly generated an IP address: #{ip_address}"

      # Create & return the entity
      e = _create_entity("IpAddress", {"name" => ip_address })
      _create_network_service_entity(e,443)
      _create_network_service_entity(e,21)
      _create_network_service_entity(e,22)
      _create_network_service_entity(e,23)
      _create_network_service_entity(e,25)

    end

  end

end
end
end
