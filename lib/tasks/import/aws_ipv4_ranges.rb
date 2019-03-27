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
      :allowed_types => ["AwsRegion"],
      :example_entities => [
        {"type" => "AwsRegion", "details" => {"name" => "us-east-1"}}
      ],
      :allowed_options => [
        {:name => "service", :regex => "alpha_numeric", :default => "EC2" },
        {:name => "limit", :regex => "alpha_numeric", :default => 10000 },
      ],
      :created_types => ["NetBlock"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    region =  _get_entity_name || "all"
    service = _get_option("service") || "EC2"
    limit = _get_option("limit").to_i || 10000

    range_data = JSON.parse(http_get_body("https://ip-ranges.amazonaws.com/ip-ranges.json"))
    range_data["prefixes"].each do |range|
      _log "Parsing... #{range}"

      limit-=1
      if limit == 0
        _log "Hit limit, exiting!"
        return
      end
      next unless (region == "#{range["region"]}" || region == "all")
      next unless (service == "#{range["service"]}" || service == "all")

      prefix = "#{range["ipv6_prefix"]}#{range["ip_prefix"]}"
      _log " -> Creating #{prefix}"

      _create_entity("NetBlock", {
         "name" => "#{prefix}", "aws_region" => region, "aws_service" => service
      })
    end

  end

end
end
end
