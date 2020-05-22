module Intrigue
module Task
class CloudflareZones < BaseTask

  def self.metadata
    {
      :name => "cloudflare_zones",
      :pretty_name => "Cloudflare Zones",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits the Cloudflare API for a domain name along with its subdomains and other identities",
      :references => ["https://api.cloudflare.com/"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","String"],
      :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    email =_get_task_config("cloudflare_username")
    key =_get_task_config("cloudflare_api_key")

    headers = {
      "X-Auth-Email" => email,
      "X-Auth-Key" => key,
      "Accept" =>  "application/json" }

    # Def cloudflare_connection (email, key, entity_name)
    Cloudflare.connect(key: key, email: email) do |connection|

      # Get all available zones:
      zones = connection.zones
      zone = connection.zones.find_by_name(entity_name)

      # Get DNS records for a given zone:
      dns_records = zone.dns_records

      # Show some details of the DNS record:
      dns_record = dns_records.first

      # Get the zone id
      zone_id = dns_record.zone_id

      # Initialize page number
      page_num = 1

      # Call the cloudflare Api
      json = call_api zone_id,page_num,headers

      # Check if the result is not empty
      if json["result"]
        json["result"].each do |e|
          _create_entity("DnsRecord", {"name" => e["name"], "content" => e["content"]})
        end
      end

      # Handel the paging issue
      while json["result_info"]["total_pages"] > page_num
        page_num += 1

        # Call the cloudflare Api
        json = call_api zone_id,page_num,headers

        # Check if the result is not empty
        if json["result"]
          json["result"].each do |e|
            _create_entity("DnsRecord", {"name" => e["name"], "content" => e["content"]})
          end
        end
      end
      end
  end #end run

  # Call the cloudflare Api function
  def call_api (zone_id,page_num,headers)
    response = http_get_body("https://api.cloudflare.com/client/v4/zones/#{zone_id}/dns_records&page=#{page_num}",nil,headers)
    json = JSON.parse(response)
  return json
  end

end #end class
end
end
