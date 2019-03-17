module Intrigue
module Task
class AwsS3PutFile < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "aws_s3_put_file",
      :pretty_name => "AWS S3 Put File",
      :authors => ["jcran"],
      :description => "This task puts a file into a specified S3 bucket.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["AwsS3Bucket"],
      :example_entities => [
        {"type" => "AwsS3Bucket", "details" => {"name" => "test"}}
      ],
      :allowed_options => [],
      :created_types => ["DnsRecord"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super
    bucket_url = _get_entity_name
    bucket_name = bucket_url.split("//").last.split(".").first
    _log "Working on bucket: #{bucket_name}"
    
    
    _log "Trying public file write"
    positive_result = _write_test_file(bucket_name) # try public first

    unless positive_result # try non-public file if we can't write a public
      _log "Trying private file write"
      _write_test_file(bucket_name, false) 
    end

  end

  def _write_test_file(bucket_name, public=true)

    access_key_id = _get_task_config "aws_access_key_id"
    secret_access_key = _get_task_config "aws_secret_access_key"
    
    connection = Fog::Storage.new({
      :provider                 => 'AWS',
      :aws_access_key_id        => access_key_id,
      :aws_secret_access_key    => secret_access_key
    })

    begin 
       dir = connection.directories.new(:key => bucket_name )# no request mad

      random_number = "#{rand(100000000)}"
      file_name = "intrigue-test-#{random_number}.html"
      file_contents = "<html><title>testing!</title><body><h1>intrigue test: #{random_number}</h1></body></html>"
      
      file = dir.files.create(
        :key    => file_name,
        :body   => file_contents,
        :public => public  
      )

      _log_good "Successful write to #{public ? "public" : "private"} file: #{_get_entity_name}/#{file_name}"

    rescue Excon::Error::Forbidden => e
      _log_error "Permission denied writing #{public ? "public" : "private"} file."
      return false
    end

  true
  end

end
end
end
