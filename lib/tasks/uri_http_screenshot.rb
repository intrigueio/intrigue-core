require 'ipaddr'
require 'screencap'

module Intrigue
class UriHttpScreenshot < BaseTask

  def metadata
    {
      :name => "uri_http_screenshot",
      :pretty_name => "URI HTTP Screenshot",
      :authors => ["jcran"],
      :description => "This task screenshots a Uri.",
      :references => [],
      :allowed_types => ["IpAddress","NetBlock","Uri"],
      :example_entities => [
        {"type" => "Uri", "attributes" => {"name" => "http://www.intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types =>  ["Screenshot"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    name = _get_entity_attribute "name"

    if @entity.type == "Uri"
      targets = [name]
    elsif @entity.type == "IpAddess"
      targets = ["http://#{name}","https://#{name}"]
    elsif @entity.type == "NetBlock"
      targets = []
      IPAddr.new(name).to_range.each{|x| targets << "http://#{x}"; targets << "https://#{x}"}
    end

    @task_log.log "Screenshotting targets:\n#{targets.join{", "}}"

    targets.each do |target_uri|

      begin

        filename = "screenshot_#{target_uri}_#{DateTime.now}.png"
        full_path = "#{Dir.pwd}/public/screenshots/#{filename}"

        f = Screencap::Fetcher.new(target_uri)
        screenshot = f.fetch(
          :output => full_path, # don't forget the extension!
        )

        @task_log.good "Saved to #{full_path}"
        _create_entity "Screenshot", {
          "name" => "#{target_uri}_screenshot",
          "uri" => "#{$intrigue_server_uri}/screenshots/#{filename}"
        }

        @task_log.log "Saved to... #{full_path}"

      rescue Screencap::Error => e
        @task_log.error "Unable to capture screenshot: #{e}"
      end

    end

  end

end
end
