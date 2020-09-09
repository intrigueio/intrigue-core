module Intrigue
module Task
class SearchBlobTest < BaseTask

  def self.metadata
    {
      :name => "search_azure_blob_test",
      :pretty_name => "search Azure",
      :authors => ["Anas ben salah"],
      :description => "This task simply creates an entity.",
      :references => [],
      :type => "Discovery",
      :passive => true,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    name = _get_entity_name
    type = _get_entity_type_string
    e = _create_entity type, {"name" => name }

  end

end
end
end
