module Intrigue
module Task
class AwsS3Loot < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "aws_s3_loot",
      :pretty_name => "AWS S3 Loot",
      :authors => ["jcran"],
      :description => "This task takes an S3 bucket and gathers all URIs.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["AwsS3Bucket"],
      :example_entities => [
        {"type" => "AwsS3Bucket", "details" => {"name" => "https://s3.amazonaws.com/bucket"}}
      ],
      :allowed_options => [ ],
      :created_types => ["DnsRecord"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super
    bucket_uri = _get_entity_name
    bucket_uri.chomp!("/")

    unless bucket_uri =~ /s3.amazonaws.com/
      _log_error "Not an Amazon S3 link?"
      return
    end

    [*('a'..'z'),*('A'..'Z'),*('0'..'9')].each do |letter|
      doc = Nokogiri::HTML(http_get_body("#{bucket_uri}?prefix=#{letter}"))
      doc.xpath("//contents").each do |item|
        key = item.xpath("key").text
        size = item.xpath("size").text.to_i
        _log "#{size/1000}: #{bucket_uri}/#{key}"
        _create_entity("Uri", {"name" => "#{bucket_uri}/#{key}", "uri" => "#{bucket_uri}/#{key}" })
      end
    end
  end

end
end
end
