module Intrigue
module Task
class UriExtractMetadata < BaseTask

  include Intrigue::Task::Parse
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_extract_metadata",
      :pretty_name => "URI Extract Metadata",
      :authors => ["jcran"],
      :description => "This task downloads the contents of a single URI and extracts entities from the text and various files. Supported formats:",
      :references => ["http://tika.apache.org/0.9/formats.html"],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => { "name" => "http://www.intrigue.io" }}
      ],
      :allowed_options => [],
      :created_types =>  ["DnsRecord","EmailAddress", "File", "Info", "Person", "PhoneNumber", "SoftwarePackage", "SslCertificate"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super
    uri = _get_entity_name

    hostname = URI.parse(uri).host
    port = URI.parse(uri).port

    download_and_extract_metadata uri

  end


end
end
end
