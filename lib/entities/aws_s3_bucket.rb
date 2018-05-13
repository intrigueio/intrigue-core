module Intrigue
module Entity
class AwsS3Bucket < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "AwsS3Bucket",
      :description => "An S3 Bucket",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /s3.amazonaws.com/
  end

  def detail_string
    "File count: #{details["contents"].count}" if details["contents"]
  end

  def enrichment_tasks
    ["enrich/aws_s3_bucket"]
  end

end
end
end


module Intrigue
module Task
class EnrichAwsS3Bucket < BaseTask

  def self.metadata
    {
      :name => "enrich/aws_s3_bucket",
      :pretty_name => "AWS S3 Loot",
      :authors => ["jcran"],
      :description => "This task takes an S3 bucket and gathers all objects within it.",
      :references => [],
      :type => "enrichment",
      :passive => true,
      :allowed_types => ["AwsS3Bucket"],
      :example_entities => [
        {"type" => "AwsS3Bucket", "details" => {"name" => "https://s3.amazonaws.com/bucket"}}
      ],
      :allowed_options => [
        {:name => "slack_notify_on_large_files",  :regex => "boolean", :default => true },
        {:name => "large_file_size", :regex => "integer", :default => 15},
      ],
      :created_types => ["DnsRecord"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    bucket_uri = _get_entity_detail("uri") || _get_entity_name
    bucket_uri.chomp!("/")

    unless bucket_uri =~ /s3.amazonaws.com/
      _log_error "Not an Amazon S3 link?"
      return
    end

    # DO THE BRUTEFORCE
    # TODO - this is very naive right now, and will miss
    # large swaths of files that have similar names. make a point
    # of making this much smarter without doing too much bruting...
    contents = []
    large_files = []

    # for each letter of the alphabet...
    [*('a'..'z'),*('A'..'Z'),*('0'..'9')].each do |letter|
      result = get_contents_unauthenticated(bucket_uri,letter)
      contents.concat(result[:contents])
      large_files.concat(result[:large_files])
    end

    _set_entity_detail("contents", contents.sort.uniq)
    _set_entity_detail("large_files", large_files.sort.uniq)

    # this should be a "Finding" or some sort of success event ?
    if large_files.sort.uniq.count > 0
      _call_handler("slackbot_buckets") if _get_option("slack_notify_on_large_files")
    end

    _finalize_enrichment
  end

  def get_contents_unauthenticated(s3_uri, prefix)
    full_uri = "#{s3_uri}?prefix=#{prefix}&max-keys=1000"

    result = http_get_body("#{full_uri}")
    return unless result

    contents = []
    large_files = []

    doc = Nokogiri::HTML(result)
    if  ( doc.xpath("//code").text =~ /NoSuchBucket/ ||
          doc.xpath("//code").text =~ /InvalidBucketName/ ||
          doc.xpath("//code").text =~ /AllAccessDisabled/ ||
          doc.xpath("//code").text =~ /AccessDenied/
          doc.xpath("//code").text =~ /PermanentRedirect/ )
      _log_error "Got response: #{doc.xpath("//code").text} (#{s3_uri})"
    else # check each file size
      doc.xpath("//contents").each do |item|

        # look at each item
        key = item.xpath("key").text
        size = item.xpath("size").text.to_i
        item_uri = "#{s3_uri}/#{key}"

        # add to our contents arrray
        contents << "#{item_uri}"

        # handle our large (interesting) files
        large_file_size = _get_option("large_file_size")
        if (size * 1.0 / 1000000) > large_file_size
          _log "Large File: #{item_uri} (#{size*1.0/1000000}MB)"

          if _get_option "slack_notify_on_large_files"
            _log_good "Notifying slack after finding large file of size #{size}: #{key}"

            large_files << "#{item_uri}"
          end
        end
      end # end parsing of the bucket

    end

  #return hash
  {contents: contents, large_files: large_files}
  end

end
end
end
