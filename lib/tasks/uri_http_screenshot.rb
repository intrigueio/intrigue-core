require 'ipaddr'
require 'screencap'

module Intrigue
class UriHttpScreenshot < BaseTask

  include Intrigue::Task::Scanner

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
      screencap(name)
    elsif @entity.type == "IpAddess" || @entity.type == "NetBlock"
      scan_for_webservers(name) do |uri|
        screencap(uri)
      end
    end

  end

  def screencap(target_uri)
    begin
      filename = "screenshot_#{target_uri}_#{DateTime.now}".gsub(/[:|\/|\.|+]/, '_') + ".png"
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
