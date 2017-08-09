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
      :allowed_types => ["*"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "test"}}
      ],
      :allowed_options => [
        {:name => "use_creds", :type => "Boolean", :regex => "boolean", :default => true },
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
      pb.chomp!


      # Authenticated method
      if opt_use_creds



        access_key_id = _get_global_config "aws_access_key_id"
        secret_access_key = _get_global_config "aws_secret_access_key"

        unless access_key_id && secret_access_key
          _log_error "You must specify a aws_access_key_id aws_secret_access_key in the config!"
          return
        end

        s3_errors = [Aws::S3::Errors::AccessDenied, Aws::S3::Errors::AllAccessDisabled,
          Aws::S3::Errors::InvalidBucketName, Aws::S3::Errors::NoSuchBucket,
          Aws::S3::Errors::PermanentRedirect ]

        Aws.config[:credentials] = Aws::Credentials.new(access_key_id, secret_access_key)
        s3 = Aws::S3::Client.new
        begin
          resp = s3.list_objects(bucket: "#{pb}", max_keys: 2)
          resp.contents.each do |object|

            # S3 URI
            s3_uri = "https://#{pb}.s3.amazonaws.com"
            _log  "Got object... #{s3_uri}#{object.key}"

            _create_entity("AwsS3Bucket", {"name" => "#{s3_uri}", "uri" => "#{s3_uri}" })
          end
        rescue *s3_errors => e
          _log_error "S3 error: #{e}"
        end

      # Unauthenticated method
      else

        # Check prefix
        potential_bucket_uri = "https://#{pb}.s3.amazonaws.com"

        begin
          result = http_get_body("#{potential_bucket_uri}?max-keys=1")
          next unless result

          doc = Nokogiri::HTML(result)
          next if ( doc.xpath("//code").text =~ /NoSuchBucket/ ||
                    doc.xpath("//code").text =~ /InvalidBucketName/ ||
                    doc.xpath("//code").text =~ /AllAccessDisabled/ ||
                    doc.xpath("//code").text =~ /AccessDenied/ ||
                    doc.xpath("//code").text =~ /PermanentRedirect/)
          _create_entity("AwsS3Bucket", {"name" => "#{potential_bucket_uri}", "uri" => "#{potential_bucket_uri}" })
        rescue
        end

        # Check postfix
        potential_bucket_uri = "https://s3.amazonaws.com/#{pb}"
        begin
          result = http_get_body("#{potential_bucket_uri}?max-keys=1")
          next unless result

          doc = Nokogiri::HTML(result)
          next if ( doc.xpath("//code").text =~ /NoSuchBucket/ ||
                    doc.xpath("//code").text =~ /InvalidBucketName/ ||
                    doc.xpath("//code").text =~ /AllAccessDisabled/ ||
                    doc.xpath("//code").text =~ /AccessDenied/ ||
                    doc.xpath("//code").text =~ /PermanentRedirect/)
          _create_entity("AwsS3Bucket", {"name" => "#{potential_bucket_uri}", "uri" => "#{potential_bucket_uri}" })
        rescue
        end

      end # end if

    end # end iteration

  end

end
end
