require 'open-uri'
module Intrigue
module Task
class SearchTalosBlackList < BaseTask

  def self.metadata
    {
      :name => "search_talos_blacklist",
      :pretty_name => "Search Talos BlackList",
      :authors => ["AnasBensalah"],
      :description => "This task checks IPs vs Talos IP BlackList for maliciousness IPs ",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [
        {"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => ["IpAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Get the IpAddress
    entity_name = _get_entity_name

    # Get talos Blacklist IP
    # data = open("https://talos-intelligence-site.s3.amazonaws.com/production/document_files/files/000/089/235/original/ip_filter.blf?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIXACIED2SPMSC7GA%2F20200127%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20200127T095320Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=50bb05427739ddaa28996435ab3fc219c3734a31d194335e6ad8ee0e3c1f7540").read
    data = open("https://talosintelligence.com/documents/ip-blacklist").read
    puts data
    if data == nil
      _log_error("Unable to fetch Url !")
      return
    end

    # Create an issue if an IP found in the Talos IP Blacklist
    if data.include? entity_name
       #_create_malicious_ip_issue(entity_name, severity=4)
       source = "talosintelligence.com"
       description = "Cisco Talos Intelligence Group is one of the largest commercial threat intelligence teams in the world,"+
      "comprised of world-class researchers, analysts and engineers. These teams are supported by unrivaled telemetry and sophisticated systems to create accurate,"+
      "rapid and actionable threat intelligence for Cisco customers"

       _create_linked_issue("malicious_ip", {
         status: "confirmed",
         #description: "This IP was founded related to malicious activities in Talos Intelligence IP BlackList",
         additional_description: description,
         source: source,
         proof: "This IP was founded related to malicious activities in #{source}",
         references: []
       })

      # Also store it on the entity
       blocked_list = @entity.get_detail("detected_malicious") || []
       @entity.set_detail("detected_malicious", blocked_list.concat([{source: source}]))

    end

  end #end run

end
end
end
