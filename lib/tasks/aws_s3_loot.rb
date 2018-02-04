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
      :type => "enrichment",
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

    contents = []
    [*('a'..'z'),*('A'..'Z'),*('0'..'9')].each do |letter|
      contents.concat get_contents_unauthenticated(bucket_uri,letter)
    end

    @entity.set_detail("contents", contents.sort.uniq)
  end

  def get_contents_unauthenticated(s3_uri, prefix)
    full_uri = "#{s3_uri}?prefix=#{prefix}&max-keys=1000"

    result = http_get_body("#{full_uri}")
    return unless result

    doc = Nokogiri::HTML(result)
    if  ( doc.xpath("//code").text =~ /NoSuchBucket/ ||
          doc.xpath("//code").text =~ /InvalidBucketName/ ||
          doc.xpath("//code").text =~ /AllAccessDisabled/ ||
          doc.xpath("//code").text =~ /AccessDenied/
          doc.xpath("//code").text =~ /PermanentRedirect/ )
      _log_error "Got response: #{doc.xpath("//code").text} (#{s3_uri})"
    else
      contents = []
      doc.xpath("//contents").each do |item|

        key = item.xpath("key").text
        size = item.xpath("size").text.to_i
        item_uri = "#{s3_uri}/#{key}"
        _log "Got: #{item_uri} (#{size*1.0/1000000}MB)"
        _log_good "Large S3 file: #{key}" if size * 1.0 / 1000000 > 50.0

        contents << "#{item_uri}"
      end
    end

  contents # will be nil if we got nothing
  end

end
end
end
