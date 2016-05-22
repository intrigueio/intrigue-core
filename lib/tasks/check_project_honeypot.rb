module Intrigue
class CheckProjectHoneypot  < BaseTask

  include Intrigue::Task::Web

  def metadata
    {
      :name => "check_project_honeypot",
      :pretty_name => "Check Project Honeypot",
      :authors => ["jcran"],
      :description => "This task checks the project honeypot site for information.",
      :references => [],
      :allowed_types => ["IpAddress"],
      :example_entities => [{"type" => "IpAddress", "attributes" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => ["Info"]
    }
  end

  def run
    super

    ip_address = _get_entity_attribute "name"
    uri = "http://www.projecthoneypot.org/ip_#{ip_address}"

    @task_result.logger.log "Connecting to #{uri} for #{@entity}"

    # Get contents
    contents = http_get_body(uri)

    # If it doesn't exist, we'll get a default page, which
    # should never happen, but worth checking.
    unless contents
      @task_result.logger.log_error "Error getting site."
      return nil
    end

    #@task_result.logger.log "Got contents: #{contents}"

    target_strings = [
      {
        :regex => /This IP addresses has been seen by at least one Honey Pot/i,
        :entity_type => "Info",
        :entity_name => "Project Honeypot info for #{uri}",
        :entity_content => "This IP address has been seen by at least one Honey Pot"
      }
    ]

    # Iterate through the target strings
    target_strings.each do |target|
      matches = contents.scan(target[:regex])

      @task_result.logger.log "matches: #{matches.inspect}"

      # Iterate through all matches
      matches.each do |match|

        @task_result.logger.log_good "got match: #{match}"

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
