module Intrigue
module Task
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
      :allowed_types => ["*"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "test"}}
      ],
      :allowed_options => [
        {:name => "use_creds", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "use_file", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "brute_file", :type => "String", :regex => "filename", :default => "s3_buckets.list" },
        {:name => "additional_buckets", :type => "String", :regex => "alpha_numeric_list", :default => "" }

      ],
      :created_types => ["DnsRecord"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    bucket_name = _get_entity_name
    opt_use_file = _get_option("use_file")
    opt_filename = _get_option("brute_file")
    opt_additional_buckets = _get_option("additional_buckets")
    opt_use_creds = _get_option("use_creds")

    if opt_use_file
      _log "Using file: #{opt_filename}"
      potential_buckets = File.read("#{$intrigue_basedir}/data/#{opt_filename}").split("\n")
    else
      _log "Using provided brute list"
      potential_buckets = [bucket_name]
    end

    # add in any additional buckets to the list of potentials
    all_potential_buckets = potential_buckets.concat(opt_additional_buckets.split(","))

    # Iterate through all potential buckets
    all_potential_buckets.each do |pb|
      bucket_name = pb.strip

      # Authenticated method
      if opt_use_creds
        _log "Using authenticated method"

        access_key_id = _get_global_config "aws_access_key_id"
        secret_access_key = _get_global_config "aws_secret_access_key"

        unless access_key_id && secret_access_key
          _log_error "You must specify a aws_access_key_id aws_secret_access_key in the config!"
          return
        end

        s3_errors = [Aws::S3::Errors::AccessDenied, Aws::S3::Errors::AllAccessDisabled,
          Aws::S3::Errors::InvalidBucketName, Aws::S3::Errors::NoSuchBucket]

        Aws.config[:credentials] = Aws::Credentials.new(access_key_id, secret_access_key)
        s3 = Aws::S3::Client.new
        begin
          resp = s3.list_objects(bucket: "#{bucket_name}", max_keys: 2)
          resp.contents.each do |object|

            # S3 URI
            s3_uri = "https://#{bucket_name}.s3.amazonaws.com"
            _log  "Got object... #{s3_uri}#{object.key}"

            _create_entity("AwsS3Bucket", {"name" => "#{s3_uri}", "uri" => "#{s3_uri}" })
          end
        rescue *s3_errors => e
          _log_error "S3 error: #{e}"
        end

      # Unauthenticated method
      else
        _log "Using unauthenticated method"

        # Check prefix
        potential_bucket_uri = "https://#{bucket_name}.s3.amazonaws.com"

        begin
          result = http_get_body("#{potential_bucket_uri}?max-keys=1")
          next unless result

          doc = Nokogiri::HTML(result)
          if  ( doc.xpath("//code").text =~ /NoSuchBucket/ ||
                doc.xpath("//code").text =~ /InvalidBucketName/ ||
                doc.xpath("//code").text =~ /AllAccessDisabled/ ||
                doc.xpath("//code").text =~ /AccessDenied/
                )
            _log_error "Received: #{doc.xpath("//code").text}"
          else
            _log_good "Received: #{doc.xpath("//code").text}"
            _create_entity("AwsS3Bucket", {"name" => "#{potential_bucket_uri}", "uri" => "#{potential_bucket_uri}" })
          end

        end

        begin
          result = http_get_body("#{potential_bucket_uri}?max-keys=1")
          next unless result

          if  ( doc.xpath("//code").text =~ /NoSuchBucket/ ||
                doc.xpath("//code").text =~ /InvalidBucketName/ ||
                doc.xpath("//code").text =~ /AllAccessDisabled/ ||
                doc.xpath("//code").text =~ /AccessDenied/ )
            _log_error "Received: #{doc.xpath("//code").text}"
          else
            _log_good "Success on #{potential_bucket_uri}!"
            _create_entity("AwsS3Bucket", {"name" => "#{potential_bucket_uri}", "uri" => "#{potential_bucket_uri}" })
          end

        end

      end # end if

    end # end iteration

  end

end
end
end
