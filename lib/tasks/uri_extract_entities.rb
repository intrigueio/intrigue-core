module Intrigue
module Task
class UriExtractEntities < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_extract_entities",
      :pretty_name => "URI Extract Entities",
      :authors => ["jcran"],
      :description => "This task requests single URI and extracts entities from the text and metadata of the content. Many file types are supported.",
      :references => [
        "http://tika.apache.org/0.9/formats.html"
      ],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => { "name" => "http://www.intrigue.io" }}
      ],
      :allowed_options => [],
      :created_types =>  ["DnsRecord", "Domain", "CreditCard", "EmailAddress",
        "Person", "PhoneNumber", "SslCertificate", "Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    url = _get_entity_name

    # download the file and extract entities 
    if metadata = download_and_extract_metadata(url)
      # set the metadata details
      _set_entity_detail("extended_metadata",metadata)
    else 
      body = http_get_body(url)
      parse_and_create_entities_from_content(url, body.gsub(/%2f/i,""))
    end
    
  end

end
end
end
