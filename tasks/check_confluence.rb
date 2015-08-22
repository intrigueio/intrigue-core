module Intrigue
class CheckConfluence  < BaseTask

  include Intrigue::Task::Web

  def metadata
    {
      :name => "check_confluence",
      :pretty_name => "Check Confluence",
      :authors => ["jcran"],
      :description => "This task checks Atlassian Cloud for the presence of a wiki.",
      :references => [],
      :allowed_types => ["String"],
      :example_entities => [{"type" => "String", "attributes" => {"name" => "intrigue"}}],
      :allowed_options => [],
      :created_types => ["Uri"]
    }
  end

  def run
    super

    name = _get_entity_attribute "name"

    ###
    ### Check for Site existence
    ###
    uri = "https://#{name}.atlassian.net/login"
    @task_log.log "Connecting to #{uri} for #{name}"

    # Prevent encoding errors
    contents = http_get_body(uri)

    # If it doesn't exist, we'll just get an empty contents
    unless contents
      @task_log.error "Site not found."
      return nil
    end

    ## XXX - we need to check for:
    # This site does not have a valid license. If you are the site administrator, proceed to My Atlassian for further information.
    # admin.atlassian.net

    target_strings = [
      {
        :regex => /Atlassian Cloud/i,
        :entity_type => "WebApplication",
        :entity_name => "#{uri}",
        :entity_content => "Atlassian Cloud"
      }
    ]

    # Iterate through the target strings
    target_strings.each do |target|
      matches = contents.scan(target[:regex])

      @task_log.log "matches: #{matches.inspect}"

      # Iterate through all matches
      matches.each do |match|

        @task_log.good "got match: #{match}"

        _create_entity("#{target[:entity_type]}",
          { "name" => "#{target[:entity_name]}",
            "uri" => "#{uri}",
            "content" => "#{target[:entity_content]} on #{uri}" })

      end if matches # << if it exists
    end
    # End interation through the target strings

    ###
    ### Check for Self Signup
    ###
    uri = "https://#{name}.atlassian.net/admin/users/sign-up"
    @task_log.log "Connecting to #{uri} for #{name}"
    contents = http_get_body(uri)

    # If it doesn't exist, we'll just get an empty contents
    unless contents
      @task_log.error "Site not found."
      return nil
    end

    target_strings = [
      {
        :regex => /User management/i,
        :entity_type => "Uri",
        :entity_name => "#{uri}",
        :entity_content => "Atlassian Cloud Self Signup"
      }
    ]

    # Iterate through the target strings
    target_strings.each do |target|
      matches = contents.scan(target[:regex])

      @task_log.log "matches: #{matches.inspect}"

      # Iterate through all matches
      matches.each do |match|

        @task_log.good "got match: #{match}"

        _create_entity("#{target[:entity_type]}",
          { "name" => "#{target[:entity_name]}",
            "uri" => "#{uri}",
            "content" => "#{target[:entity_content]} on #{uri}" })

      end if matches # << if it exists
    end
    # End interation through the target strings


  end

end
end
