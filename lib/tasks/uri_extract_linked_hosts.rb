module Intrigue
module Task
class UriExtractLinkedHosts  < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_extract_linked_hosts",
      :pretty_name => "URI Extract Linked Hosts",
      :authors => ["jcran"],
      :description => "This task analyzes and extracts hosts from links.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "extract_patterns", :regex => "alpha_numeric_list", :default => "default" },
      ],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    # Go collect the page's contents
    uri = _get_entity_name
    contents = http_get_body(uri)

    # default to our name for the extract pattern
    if _get_option("extract_patterns") != "default"
      extract_patterns = _get_option("extract_patterns").split(",")
    else
      extract_patterns = []
    end

    unless contents
      _log_error "Unable to retrieve uri: #{uri}"
      return
    end

    ###
    ## Parse contents for s3 buckets
    ###
    URI.extract(contents).each do |s|
      next unless extract_bucket_name_from_uri(s)

      _log "Found S3 bucket: #{s}"
      _create_entity 'AwsS3Bucket', {
        'name' => extract_bucket_name_from_uri(s),
        'bucket_name' => extract_bucket_name_from_uri(s),
        'bucket_uri' => "#{extract_bucket_name_from_uri(s)}.s3.amazonaws.com" # convert to virtual path style
      }
    end

    ###
    ### Now, parse out all links and do analysis on
    ### the individual links
    ###
    out = parse_dns_records_from_content(uri, contents.gsub(/%2f/i,""), extract_patterns)
    out.each do |d|
      create_dns_entity_from_string d["name"], nil, false, d
    end

  end

end
end
end
