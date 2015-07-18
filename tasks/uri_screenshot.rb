require 'screencap'

class UriScreenshot < BaseTask

  def metadata
    { :version => "1.0",
      :name => "uri_screenshot",
      :pretty_name => "URI Screenshot",
      :authors => ["jcran"],
      :description => "This task screenshots a Uri.",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [
        {:type => "Uri", :attributes => {:name => "http://www.intrigue.io"}}
      ],
      :allowed_options => [  ],
      :created_types =>  ["Screenshot"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_attribute "name"
    filename = "screenshot_#{rand(100000000000000)}.png"
    full_path = "#{Dir.pwd}/public/screenshots/#{filename}"

    begin
      @task_log.log "Saving to... #{full_path}"

      f = Screencap::Fetcher.new(uri)
      screenshot = f.fetch(
        :output => full_path, # don't forget the extension!
        # optional:
        #:div => '.header', # selector for a specific element to take screenshot of
        #:width => 1024,
        #:height => 768,
        #:top => 0, :left => 0, :width => 100, :height => 100 # dimensions for a specific area
      )

      @task_log.good "Saved to #{full_path}"
      _create_entity "Screenshot", :name => "#{uri}_screenshot", :uri => "#{$intrigue_server_uri}/screenshots/#{filename}"

    rescue Screencap::Error => e
      @task_log.error "Unable to capture screenshot: #{e}"
    end

  end

end
