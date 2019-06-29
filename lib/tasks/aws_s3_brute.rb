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
      :allowed_types => ["DnsRecord","Domain","EmailAddress","IpAddress","Person","Organization","String"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "test"}}
      ],
      :allowed_options => [
        {:name => "threads", :regex => "integer", :default => 1 },
        {:name => "use_creds",:regex => "boolean", :default => false },
        {:name => "create_permutations",:regex => "boolean", :default => true },
        {:name => "use_file", :regex => "boolean", :default => false },
        {:name => "brute_file",:regex => "filename", :default => "s3_buckets.list" },
        {:name => "additional_buckets", :regex => "alpha_numeric_list", :default => "" }
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
    opt_threads = _get_option("threads")
    opt_permute = _get_option("create_permutations")

    if opt_use_file
      _log "Using file: #{opt_filename}"
      potential_buckets = File.read("#{$intrigue_basedir}/data/#{opt_filename}").split("\n")
    else
      _log "Using provided brute list"
      potential_buckets = [bucket_name]
    end

    # add in any additional buckets to the list of potentials
    all_potential_buckets = potential_buckets.concat(opt_additional_buckets.split(","))

    # Create our queue of work from the checks in brute_list
    work_q = Queue.new
    all_potential_buckets.each do |pb|
      work_q << pb.strip

      # Add permutations
      if opt_permute
        begin
          
          # AWS is case sensitive.
          # https://forums.aws.amazon.com/thread.jspa?threadID=19928
          first_letter_cap = "#{pb.strip}".slice(0,1).upcase + "#{pb.strip}".slice(1..-1)
          #work_q << "#{first_letter_cap}" unless "#{first_letter_cap}" == "#{pb.strip}"
          #work_q << "#{pb.strip.upcase}" unless "#{pb.strip.upcase}" == "#{pb.strip}"
          #work_q << "#{pb.strip.downcase}" unless "#{pb.strip.downcase}" == "#{pb.strip}"

          # General development permutations
          work_q << "#{pb.strip}-backup"
          work_q << "#{pb.strip}-beta"
          work_q << "#{pb.strip}-dev"
          work_q << "#{pb.strip}-development"
          work_q << "#{pb.strip}-eng"
          work_q << "#{pb.strip}-engineering"
          work_q << "#{pb.strip}-old"
          work_q << "#{pb.strip}-prod"
          work_q << "#{pb.strip}-qa"
          work_q << "#{pb.strip}-stage"
          work_q << "#{pb.strip}-staging"
          work_q << "#{pb.strip}-test"
          work_q << "#{pb.strip}-web"
          work_q << "backup-#{pb.strip}"
          work_q << "beta-#{pb.strip}"
          work_q << "dev-#{pb.strip}"
          work_q << "development-#{pb.strip}"
          work_q << "eng-#{pb.strip}"
          work_q << "engineering-#{pb.strip}"
          work_q << "old-#{pb.strip}"
          work_q << "prod-#{pb.strip}"
          work_q << "qa-#{pb.strip}"
          work_q << "stage-#{pb.strip}"
          work_q << "staging-#{pb.strip}"
          work_q << "test-#{pb.strip}"
          work_q << "web-#{pb.strip}"
          
        rescue TypeError => e
          puts "Unable to permute: #{pb}, failing"
        end
      end

    end

    # Create a pool of worker threads to work on the queue
    workers = (0...opt_threads).map do
      Thread.new do
        begin
          while bucket_name = work_q.pop(true)

            #skip anything that isn't a real name
            next unless bucket_name && bucket_name.length > 0

            s3_uri = "https://#{bucket_name}.s3.amazonaws.com"

            # Authenticated method
            if opt_use_creds

              access_key_id = _get_task_config "aws_access_key_id"
              secret_access_key = _get_task_config "aws_secret_access_key"

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
            
              exists = check_existence_unauthenticated(s3_uri,bucket_name)

              if exists
                _create_entity("AwsS3Bucket", {
                  "name" => "#{s3_uri}",
                  "uri" => "#{s3_uri}",
                  "authenticated" => false
                }) 

                # create a bucket issue 
                create_s3_bucket_issue s3_uri 
              end

              ### and if we got it there, no need to continue
              next unless !exists 

              #### but if not, try the old format 
              s3_uri = "https://s3.amazonaws.com/#{bucket_name}"
              exists = check_existence_unauthenticated(s3_uri,bucket_name)

              if exists 
                # create a bucket issue
                create_s3_bucket_issue s3_uri

                _create_entity("AwsS3Bucket", {
                  "name" => "#{s3_uri}",
                  "uri" => "#{s3_uri}",
                  "authenticated" => false,
                }) 
              end

            end # end if opt_use_creds


          end # end while
        rescue ThreadError
        end
      end
    end; "ok"
    workers.map(&:join); "ok"

  end

  # TODO... check contents before creating an issue?
  def create_s3_bucket_issue(url)

    _create_issue({
      name: "Open s3 bucket: #{url}",
      type: "s3_bucket",
      severity: 5,
      status: "potential",
      description: "Investigate this open s3 bucket",
      details: { url: url }
    })

  end


  def check_existence_unauthenticated(s3_uri, key)
    response = http_get_body("#{s3_uri}?max-keys=1")
    exists = false
    return exists unless response

    doc = Nokogiri::HTML(response)
    if  ( doc.xpath("//code").text =~ /NoSuchBucket/ ||
          doc.xpath("//code").text =~ /InvalidBucketName/ ||
          doc.xpath("//code").text =~ /AllAccessDisabled/ ||
          doc.xpath("//code").text =~ /AccessDenied/ ||
          doc.xpath("//code").text =~ /PermanentRedirect/)

      _log_error "Got negative response: #{doc.xpath("//code").text} (#{s3_uri})"

    elsif doc.xpath("//name").text =~ /#{key}/
      
      _log "Got positive response: #{response}"
      exists = true

    else 

      _log "Got unknown response: #{response}"

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

    begin
      # check prefix
      s3 = Aws::S3::Client.new({region: 'us-east-1'})
      resp = s3.list_objects(bucket: "#{bucket_name}", max_keys: 1000)
      exists = true

    rescue Aws::S3::Errors::PermanentRedirect => e 
      _log_error "Permanent redirect: #{e} (region?)"
    rescue *s3_errors => e
      _log_error "S3 error: #{e} (#{bucket_name})"
    end

  exists # will be nil if we got nothing
  end


end
end
end
