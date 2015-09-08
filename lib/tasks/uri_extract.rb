module Intrigue
class UriExtract < BaseTask

  include Intrigue::Task::Parse

  def metadata
    {
      :name => "uri_extract",
      :pretty_name => "URI Extract",
      :authors => ["jcran"],
      :description => "This task downloads the contents of a URI and extracts entities from the text and metadata.",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "attributes" => { "name" => "http://www.intrigue.io" }}
      ],
      :allowed_options => [],
      :created_types =>  ["DnsRecord", "EmailAddress", "File", "Info", "Person", "PhoneNumber", "SoftwarePackage"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super
    uri = _get_entity_attribute "name"
    download_and_extract_metadata uri
  end

end
end
