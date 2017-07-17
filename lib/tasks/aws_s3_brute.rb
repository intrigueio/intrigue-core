module Intrigue
class AwsS3Brute < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "aws_s3_brute",
      :pretty_name => "AWS S3 Brute",
      :authors => ["jcran"],
      :description => "This task takes a list of names and determines if they're valid s3 buckets.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "attributes" => {"name" => "test,test2,test3"}}
      ],
      :allowed_options => [
        {:name => "use_file", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "brute_file", :type => "String", :regex => "filename", :default => "s3_buckets.list" },
      ],
      :created_types => ["DnsRecord"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    opt_use_file = _get_option("use_file")
    opt_filename = _get_option("brute_file")

    if opt_use_file
      _log "Using file: #{opt_filename}"
      potential_buckets = File.read("#{$intrigue_basedir}/data/#{opt_filename}").split("\n")
    else
      _log "Using provided brute list"
      potential_buckets = _get_entity_name.split(",")
    end

    potential_buckets.each do |pb|

      pb.chomp!

      # Check prefix
      potential_bucket_uri = "https://#{pb}.s3.amazonaws.com?max-keys=1"
      doc = Nokogiri::HTML(http_get_body("#{potential_bucket_uri}"))
      next if ( doc.xpath("//code").text =~ /NoSuchBucket/ ||
                doc.xpath("//code").text =~ /InvalidBucketName/ ||
                doc.xpath("//code").text =~ /AllAccessDisabled/ ||
                doc.xpath("//code").text =~ /AccessDenied/ ||
                doc.xpath("//code").text =~ /PermanentRedirect/)
      _create_entity("AwsS3Bucket", {"name" => "#{potential_bucket_uri}", "uri" => "#{potential_bucket_uri}" })
    end

    potential_buckets.each do |pb|
      # Check postfix
      potential_bucket_uri = "https://s3.amazonaws.com/#{pb}?max-keys=1"
      doc = Nokogiri::HTML(http_get_body("#{potential_bucket_uri}"))
      next if ( doc.xpath("//code").text =~ /NoSuchBucket/ ||
                doc.xpath("//code").text =~ /InvalidBucketName/ ||
                doc.xpath("//code").text =~ /AllAccessDisabled/ ||
                doc.xpath("//code").text =~ /AccessDenied/ ||
                doc.xpath("//code").text =~ /PermanentRedirect/)
      _create_entity("AwsS3Bucket", {"name" => "#{potential_bucket_uri}", "uri" => "#{potential_bucket_uri}" })
    end

  end

end
end
