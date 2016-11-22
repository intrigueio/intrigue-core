module Intrigue
class UriGatherTechnologyTask  < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_gather_technology",
      :pretty_name => "URI Gather Technology",
      :authors => ["jcran"],
      :description => "This task determines platform and technologies of the target.",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "attributes" => {:name => "http://www.intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["SoftwarePackage"]
    }
  end

  def run
    super

    uri = _get_entity_attribute "name"
    _log "Connecting to #{uri} for #{@entity}"

    # Gather the page body
    response = http_get(uri)
    contents = response.body

    unless contents
      _log "Error! Unable to retrieve task"
      return
    end

    # Iterate through the target strings, which can be found in the web mixin
    http_body_checks.each do |check|
      matches = contents.scan(check[:regex])

      # Iterate through all matches
      matches.each do |match|
       _create_entity("SoftwarePackage",
        { "name" => "#{check[:finding_name]}",
          "uri" => "#{uri}",
          "content" => "Found #{match} on #{uri}" })
      end if matches
    end
    # End interation through the target strings

  end

end
end
