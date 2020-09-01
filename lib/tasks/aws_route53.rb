module Intrigue
module Task
class AWSroute53 < BaseTask

  def self.metadata
    {
      :name => "aws_route53",
      :pretty_name => "AWS Route53",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits the Route53 API for enumerating Dns Records for a specific domain",
      :references => ["https://docs.aws.amazon.com/Route53/latest/APIReference/Welcome.html"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [{"type" => "Domain", "details" => {"name" => "letshopeit.works"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Get the entity name to investigate
    entity_name= _get_entity_name

    # set zoneid
    zoneid = "unknown"

    # Get the AWS Route53 Credentials
    r53 = Aws::Route53::Client.new({
      region: _get_task_config("aws_region"),
      access_key_id: _get_task_config("aws_access_key_id"),
      secret_access_key: _get_task_config("aws_secret_access_key")
    })

    # Get the zones
    resp = r53.list_hosted_zones

    resp[:hosted_zones].each do |zone|

      #check if the zone name matches the domain to investigate
      if zone[:name].include? entity_name

        zoneid = zone[:id]
        # info on zone
        zoneinfo = r53.get_hosted_zone({:id => zoneid})
        #records = r53.list_resource_record_sets({:hosted_zone_id => zoneid})
        # create nameservers for each zone
        zoneinfo["delegation_set"]["name_servers"].each do |e|

          _create_entity("Nameserver", {"name" => (e).to_s})
        end

        #all records for zone
        #records = r53.list_resource_record_sets({:hosted_zone_id => zoneid})
        #puts records

      end
    end



  end #end run


end #end class
end
end
