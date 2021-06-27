module Intrigue
module Task
class ImportArinIpv4Ranges < BaseTask

  include Intrigue::Task::Data

  def self.metadata
    {
      :name => "import/arin_ipv4_ranges",
      :pretty_name => "Import ARIN IPv4 Ranges",
      :authors => ["jcran"],
      :description => "This gathers the allocated ipv4 ranges from ARIN and creates NetBlocks.",
      :references => [],
      :type => "import",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "__IGNORE__"}}
      ],
      :allowed_options => [
        {:name => "filter", :regex => "alpha_numeric", :default => "ALLOCATED" },
      ],
      :created_types => ["NetBlock"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super
    filter = _get_option("filter") || "ALLOCATED"
    _allocated_ipv4_ranges(filter).each do |range|
      _create_entity("NetBlock", {
        "name" => "#{range}",
        "scoped" => true
      })
    end

  end

end
end
end
