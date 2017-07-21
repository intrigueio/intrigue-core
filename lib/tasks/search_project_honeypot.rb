module Intrigue
class SearchProjectHoneypot < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "search_project_honeypot",
      :pretty_name => "Search Project Honeypot",
      :authors => ["jcran"],
      :description => "This task checks the projecthoneypot site for information.",
      :references => [],
      :allowed_types => ["IpAddress"],
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => ["Info"]
    }
  end

  def run
    super

    name = _get_entity_name
    uri = "http://www.projecthoneypot.org/ip_#{name}"

    _log "Connecting to #{uri} for #{@entity}"

    # Get contents
    contents = http_get_body(uri)

    # If it doesn't exist, we'll get a default page, which
    # should never happen, but worth checking.
    unless contents
      _log_error "Error getting site."
      return nil
    end

    #_log "Got contents: #{contents}"

    target_strings = [
      {
        :regex => /This IP addresses has been seen by at least one Honey Pot/i,
        :entity_type => "Info",
        :entity_name => "Project Honeypot result for #{uri}",
        :entity_content => "This IP address has been seen by at least one Honey Pot"
      }
    ]

    # Iterate through the target strings
    target_strings.each do |target|
      matches = contents.scan(target[:regex])

      _log "Matches: #{matches.inspect}"

      # Iterate through all matches
      matches.each do |match|

        _log_good "Got a match: #{match}"

        _create_entity("Info",
          { "name" => "#{target[:entity_name]}",
            "uri" => "#{uri}",
            "content" => "#{target[:entity_content]} on #{uri}" })

      end if matches # << if it exists
    end
    # End interation through the target strings

  end

end
end
