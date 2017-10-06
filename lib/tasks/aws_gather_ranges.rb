module Intrigue
module Task
class AwsGatherRanges < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "aws_gather_ranges",
      :pretty_name => "AWS Gather Ranges",
      :authors => ["jcran"],
      :description => "This gathers the ranges from AWS.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["String"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "us-east-1"}}
      ],
      :allowed_options => [
        {:name => "service", :type => "String", :regex => "alpha_numeric", :default => "EC2" },
      ],
      :created_types => ["NetBlock"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    region = _get_entity_name
    service = _get_option("service")

    range_data = JSON.parse(http_get_body("https://ip-ranges.amazonaws.com/ip-ranges.json"))
    range_data["prefixes"].each do |range|
      _log "Parsing... #{range}"

      next unless (region == "#{range["region"]}" || region == "*")
      next unless (service == "#{range["service"]}" || service == "*")

      prefix = "#{range["ipv6_prefix"]}#{range["ip_prefix"]}"
      _log " -> Creating #{prefix}"

      _create_entity("NetBlock", {"name" => "#{prefix}", "aws_region" => region, "aws_service" => service })
    end

  end

end
end
end
