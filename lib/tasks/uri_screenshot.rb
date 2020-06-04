module Intrigue
module Task
class UriScreenshot < BaseTask

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

    old_details = _get_entity_details
    new_details = capture_screenshot_and_requests(uri)
    merged_details = new_details.merge(old_details)

    # now merge them together and set as the new details
    _set_entity_details(merged_details)

  end

end
end
end
