module Intrigue
module Task
class SearchSecurityTrails < BaseTask

  def self.metadata
    {
      :name => "search_security_trails",
      :pretty_name => "Search Security Trails",
      :authors => ["jcran"],
      :description => "This task hits the SecurityTrails API and finds matches.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["EmailAddress", "DnsRecord"],
      :example_entities => [{"type" => "Host", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord","Info"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    begin

      # Make sure the key is set
      api_key = _get_global_config "security_trails_api_key"
      entity_name = _get_entity_name

      raise "Not yet implemented"

  end # end run()

end # end Class
end
end
