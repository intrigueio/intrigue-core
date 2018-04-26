module Intrigue
module Task
class ImportAwsIpv4Ranges < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "import/aws_ipv4_ranges",
      :pretty_name => "Import AWS IPv4 Ranges",
      :authors => ["jcran"],
      :description => "This gathers the ranges from AWS.",
      :references => [],
      :type => "import",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "us-east-1"}}
      ],
      :allowed_options => [
        {:name => "service", :regex => "alpha_numeric", :default => "EC2" },
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
