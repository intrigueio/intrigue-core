module Intrigue
module Task
class UriScreenshot < BaseTask

  #include Intrigue::Task::Scanner
  include Intrigue::Task::Browser

  def self.metadata
    {
      :name => "uri_screenshot",
      :pretty_name => "URI Screenshot",
      :authors => ["jcran"],
      :description => "This task screenshots a Uri.",
      :references => [
        "https://github.com/johnmichel/Library-Detector-for-Chrome",
        "https://snyk.io/blog/77-percent-of-sites-use-vulnerable-js-libraries",
        "https://github.com/mathquill/mathquill/commit/a34fc8b5243471c7ab7044c2ba70831406caed2c"
      ],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://www.intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types =>  ["Screenshot"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_name

    # create a capybara session and browse to our uri
    session = create_browser_session(uri)

    # capture a screenshot and save it as a detail
    base64_screenshot_data = capture_screenshot(session)
    _set_entity_detail("hidden_screenshot_contents",base64_screenshot_data)

  end

end
end
end
