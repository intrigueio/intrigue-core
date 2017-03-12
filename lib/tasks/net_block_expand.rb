require 'ipaddr'

module Intrigue
class NetblockExpand < BaseTask

  def self.metadata
    {
      :name => "net_block_expand",
      :pretty_name => "NetBlock Expand",
      :authors => ["jcran"],
      :description => "This task expands a NetBlock into a list of ip addresses.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["NetBlock"],
      :example_entities => [
        {"type" => "NetBlock", "attributes" => {"name" => "10.0.0.0/24"}}
      ],
      :allowed_options => [
      ],
      :created_types => ["Host","IpAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    begin
      netblock = IPAddr.new(_get_entity_name)
      _log "Expanding Range: #{netblock}"
      netblock.to_range.to_a[1..-1].each do |r|
        _create_entity "IpAddress", "name" => r.to_s
      end
    rescue IPAddr::InvalidPrefixError => e
      _log_error "Invalid NetBlock!"
    end

  end

end
end
