module Intrigue
module Task
class UriExtractMetadata < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_extract_metadata",
      :pretty_name => "URI Extract Metadata",
      :authors => ["jcran"],
      :description => "This task downloads the contents of a single URI and extracts entities from the text and metadata of files.",
      :references => ["http://tika.apache.org/0.9/formats.html"],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => { "name" => "http://www.intrigue.io" }}
      ],
      :allowed_options => [],
      :created_types =>  ["DnsRecord","EmailAddress", "Info", "Person", "PhoneNumber", "SslCertificate", "Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # download the file and extract
    metadata = download_and_extract_metadata _get_entity_name

    # set the metadata details
    _set_entity_detail("extended_metadata",metadata)

  end

end
end
end
