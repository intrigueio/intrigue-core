module Intrigue
module Task
class ArinGatherIpv4Ranges < BaseTask
  include Intrigue::Task::Data

  def self.metadata
    {
      :name => "arin_gather_ipv4_ranges",
      :pretty_name => "ARIN Gather Allocated IPv4 Ranges",
      :authors => ["jcran"],
      :description => "This gathers the allocated ipv4 ranges from ARIN and creates NetBlocks to be Scanned.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["String"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "ALLOCATED"}}
      ],
      :allowed_options => [],
      :created_types => ["NetBlock"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super
    filter = "ALLOCATED"
    _allocated_ipv4_ranges(filter).each do |range|
      _create_entity("NetBlock", {"name" => "#{range}" })
    end

  end

end
end
end
