module Intrigue
module Task
class UriEnumerateJs  < BaseTask

  #include Intrigue::Task::Scanner
  include Intrigue::Task::Browser

  def self.metadata
    {
      :name => "uri_enumerate_js",
      :pretty_name => "URI Enumerate JS",
      :authors => ["jcran"],
      :description => "This task enumerates javascript library.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://www.intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types =>  [],
      :queue => "task_browser"
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_name

    #  Get existing software details (in case this is a second run)
    existing_libraries = _get_entity_detail("javascript") || []

    session = create_browser_session

    # Run the version checking scripts in our session (See lib/helpers/browser)
    new_libraries = gather_javascript_libraries(session, uri, existing_libraries)

    # set the new details
    _set_entity_detail("javascript", new_libraries)

    # cleanup
    session.driver.quit

  end

end
end
end
