module Intrigue
module Task
class UriScreenshot < BaseTask
  sidekiq_options :queue => "task_browser", :backtrace => true

  #include Intrigue::Task::Scanner
  include Intrigue::Task::Browser

  def self.metadata
    {
      :name => "uri_screenshot",
      :pretty_name => "URI Screenshot",
      :authors => ["jcran"],
      :description => "This task screenshots a Uri.",
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

    session = create_browser_session

    # capture a screenshot and save it as a detail
    _set_entity_detail("hidden_screenshot_contents",capture_screenshot(session, uri))

    # cleanup
    destroy_browser_session(session)

  end

end
end
end
