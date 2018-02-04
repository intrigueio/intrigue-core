module Intrigue
module Task
class AwsS3Brute < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "aws_s3_brute",
      :pretty_name => "AWS S3 Brute",
      :authors => ["jcran"],
      :description => "This task takes anything and determines if it's a valid s3 bucket name.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord","EmailAddress","IpAddress","Person","Organization","String"],
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

      # skip anything that isn't a real name
      next unless bucket_name && bucket_name.length > 0

      # Authenticated method
      if opt_use_creds

        access_key_id = _get_global_config "aws_access_key_id"
        secret_access_key = _get_global_config "aws_secret_access_key"

        unless access_key_id && secret_access_key
          _log_error "FATAL! To scan with authentication, you must specify a aws_access_key_id aws_secret_access_key in the config!"
          return
        end

        # Check for it, and get the contents
        Aws.config[:credentials] = Aws::Credentials.new(access_key_id, secret_access_key)
        exists = check_existence_authenticated(bucket_name)

        # create our entity and store the username with it
        _create_entity("AwsS3Bucket", {
          "name" => "#{s3_uri}",
          "uri" => "#{s3_uri}",
          "authenticated" => true,
          "username" => access_key_id
        }) if exists

      #########################
      # Unauthenticated check #
      #########################
      else

        s3_uri = "https://#{bucket_name}.s3.amazonaws.com"
        exists = check_existence_unauthenticated(s3_uri)
        _create_entity("AwsS3Bucket", {
          "name" => "#{s3_uri}",
          "uri" => "#{s3_uri}",
          "authenticated" => false
        }) if exists

        next if exists ## Only proceed if we got an error above (bucket exists!) !!!

        s3_uri = "https://s3.amazonaws.com/#{bucket_name}"
        exists = check_existence_unauthenticated(s3_uri)
        _create_entity("AwsS3Bucket", {
          "name" => "#{s3_uri}",
          "uri" => "#{s3_uri}",
          "authenticated" => false,
        }) if exists

      end # end if opt_use_creds
    end # end iteration
  end


  def check_existence_unauthenticated(s3_uri)
    result = http_get_body("#{s3_uri}?max-keys=1")
    return unless result

    doc = Nokogiri::HTML(result)
    if  ( doc.xpath("//code").text =~ /NoSuchBucket/ ||
          doc.xpath("//code").text =~ /InvalidBucketName/ ||
          doc.xpath("//code").text =~ /AllAccessDisabled/ ||
          doc.xpath("//code").text =~ /AccessDenied/ ||
          doc.xpath("//code").text =~ /PermanentRedirect/
        )
      _log_error "Got response: #{doc.xpath("//code").text} (#{s3_uri})"
    else
      exists = true
      end

  exists # will be nil if we got nothing
  end

  def check_existence_authenticated(bucket_name)

    s3_errors = [
      Aws::S3::Errors::AccessDenied,
      Aws::S3::Errors::AllAccessDisabled,
      Aws::S3::Errors::InvalidBucketName,
      Aws::S3::Errors::NoSuchBucket,
      Aws::Errors::MissingCredentialsError
    ]

    s3_uri = "https://#{bucket_name}.s3.amazonaws.com/"

    begin # check prefix
      s3 = Aws::S3::Client.new({region: 'us-east-1'})
      resp = s3.list_objects(bucket: "#{bucket_name}", max_keys: 1000)
      exists = true

    rescue *s3_errors => e
      _log_error "S3 error: #{e} (#{bucket_name})"
    end

  exists # will be nil if we got nothing
  end


end
end
end
