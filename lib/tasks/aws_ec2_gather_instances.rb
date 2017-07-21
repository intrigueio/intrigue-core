module Intrigue
class AwsEc2GatherInstances < BaseTask

  def self.metadata
    {
      :name => "aws_ec2_gather_instances",
      :pretty_name => "AWS EC2 Gather Instances",
      :authors => ["jcran"],
      :description => "This task enumerates machines running under an (authenticated) EC2 account.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["AwsCredential"],
      :example_entities => [{"type" => "String", "details" => {"name" => "intrigue"}}],
      :allowed_options => [
        {:name => "region", :type => "String", :regex => "alpha_numeric", :default => "us-east-1" }
      ],
      :created_types => ["IpAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Get the AWS Credentials
    aws_access_key = @entity.details["hidden_access_id"]
    aws_secret_key = @entity.details["hidden_secret_key"]

    # Get the region
    aws_region = _get_option "region"

    begin
      # Connect to AWS using fog ...
      # TODO... prob want to remove the fog dep
      ec2 = Fog::Compute.new({
        :aws_access_key_id => aws_access_key,
        :aws_secret_access_key => aws_secret_key,
        :provider => "AWS",
        :region => aws_region })

      # Pull each server out and create an IPAddress
      ec2.servers.each do |s|
        _create_entity "IpAddress", {
            "name" => "#{s.public_ip_address}",
            "aws_region" => "#{aws_region}",
            "private_dns_name" => "#{s.private_dns_name}",
            "private_ip_address" => "#{s.private_ip_address}",
            "public_dns_name" => "#{s.dns_name}"
        }
      end
    rescue Fog::Compute::AWS::Error => e
      _log_error "Error: #{e}"
    end

  end

end
end
