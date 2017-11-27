require 'mini_magick'

module Intrigue
module Task
class UriScreenshot < BaseTask

  include Intrigue::Task::Scanner

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
      :created_types =>  ["Screenshot"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    if @entity.type_string == "Uri"
      uri = _get_entity_name

      begin

        # Start a new session
        session = Capybara::Session.new(:poltergeist)

        # browse to our target
        session.visit(uri)

        # Capture Title
        page_title = session.document.title
        _log_good "Title: #{page_title}"

        # Capture JQuery version
        version = session.evaluate_script('jQuery.fn.jquery')
        _log_good "Using jQuery #{version}"
        @entity.set_detail("jquery", version)

        # Capture a screenshot, cleaning
        #
        tempfile = Tempfile.new(['phantomjs', '.png'])

        #file_path = "/tmp/intrigue-phantomjs-file-#{rand(1000000000000000)}.png"
        return_path = session.save_screenshot(tempfile.path)
        _log "Saved Screenshot to #{return_path}"

        # resize the image using minimagick
        image = MiniMagick::Image.open(return_path)
        image.resize "640x480"
        image.format "png"
        image.write tempfile.path

        # open and read the file's contents, and base64 encode them
        base64_image_contents = Base64.encode64(File.read(tempfile.path))

        # cleanup
        session.driver.quit
        tempfile.close
        tempfile.unlink

        # set the details
        @entity.set_detail("hidden_screenshot_contents",base64_image_contents)

      rescue Capybara::Poltergeist::StatusFailError => e
        _log_error "Fail Error: #{e}"
      rescue Capybara::Poltergeist::JavascriptError => e
        _log_error "JS Error: #{e}"
      end
    end

  end

end
end
end
