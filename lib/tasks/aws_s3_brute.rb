require 'nokogiri'

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
      :allowed_types => ["String"],
      :example_entities => [
        {"type" => "String", "attributes" => {"name" => ""}}
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

    bucket_uri = "https://s3.amazonaws.com"
    bucket_uri.chomp!("/")

    if opt_use_file
      _log "Using file: #{opt_filename}"
      potential_buckets = File.read("#{$intrigue_basedir}/data/#{opt_filename}").split("\n")
    else
      _log "Using provided brute list"
      potential_buckets = _get_entity_name.split(",")
    end



    potential_buckets.each do |pb|
      potential_bucket_uri = "#{bucket_uri}/#{pb}?max-keys=1"
      doc = Nokogiri::HTML(http_get_body("#{potential_bucket_uri}"))

      next if doc.xpath("//code").text =~ /NoSuchBucket/
      next if doc.xpath("//code").text =~ /AllAccessDisabled/
      next if doc.xpath("//code").text =~ /AccessDenied/

      _create_entity("Uri", {"name" => "#{potential_bucket_uri}", "uri" => "#{potential_bucket_uri}" })

      doc.xpath("//contents").each do |item|
        puts "FOUND: #{item.xpath("key").text}"
      end
    end

  end

end
end
