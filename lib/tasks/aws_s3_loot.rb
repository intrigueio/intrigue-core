

module Intrigue
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
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "attributes" => {"name" => "https://s3.amazonaws.com/bucket"}}
      ],
      :allowed_options => [ ],
      :created_types => ["DnsRecord"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    require 'nokogiri'

    bucket_uri = _get_entity_name

    unless bucket_uri =~ /https:\/\/s3.amazonaws.com/
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
