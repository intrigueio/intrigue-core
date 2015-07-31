class CheckOkta  < BaseTask

  include Task::Web

  def metadata
    {
      :name => "check_okta",
      :pretty_name => "Check Okta",
      :authors => ["jcran"],
      :description => "This task checks Okta for the presence of an account.",
      :references => [],
      :allowed_types => ["String"],
      :example_entities => [{:type => "String", :attributes => {:name => "intrigue"}}],
      :allowed_options => [],
      :created_types => ["Uri"]
    }
  end

  def run
    super

    name = _get_entity_attribute "name"

    uri = "https://#{name}.okta.com"

    @task_log.log "Connecting to #{uri} for #{@entity}"

    # Prevent encoding errors
    contents = http_get_body(uri) #.force_encoding('UTF-8')

    # If it doesn't exist, we'll get a default page, which
    # should never happen, but worth checking.
    unless contents
      @task_log.error "Error getting site."
      return nil
    end

    #@task_log.log "Got contents: #{contents}"

    target_strings = [
      { :regex => /e03d04189cf6dad3aa04270a0abd7b42/i,
        :entity_type => "Uri",
        :entity_name => "#{uri}",
        :entity_content => "Okta Account Found" }
    ]

    # Iterate through the targets
    target_strings.each do |target|

      # check for this target
      matches = contents.scan(target[:regex])

      #@task_log.log "Got matches #{matches.inspect}"

      # It's easier in this case to check and see if we got the default
      # page, which indicates that there's no account. So in the case where
      # we didn't find a match for the default, go ahead and create a webapp
      if matches.empty?

        @task_log.good "Not a default page!"

        _create_entity("#{target[:entity_type]}",
         { :name => "#{target[:entity_name]}",
           :uri => "#{uri}",
           :content => "#{target[:entity_content]} on #{uri}" })

      end

    end
    # End interation through the target strings

  end

end
