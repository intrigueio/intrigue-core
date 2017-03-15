require 'ipaddr'
require 'screencap'

module Intrigue
class UriHttpScreenshot < BaseTask

  include Intrigue::Task::Scanner

  def self.metadata
    {
      :name => "uri_http_screenshot",
      :pretty_name => "URI HTTP Screenshot",
      :authors => ["jcran"],
      :description => "This task screenshots a Uri.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Host","NetBlock","Uri"],
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

    name = _get_entity_name

    if @entity.type_string == "Uri"
      screencap(name)
    elsif @entity.type_string == "Host"
      scan_for_uris(name).each do |uri|
        screencap(uri)
      end
    end

  end

  def screencap(target_uri)
    begin
      _log "Screencapping #{target_uri}"
      filename = "screenshot_#{target_uri}_#{DateTime.now}".gsub(/[:|\/|\.|+]/, '_') + ".png"
      full_path = "#{Dir.pwd}/public/screenshots/#{filename}"

      f = Screencap::Fetcher.new(target_uri)
      screenshot = f.fetch(
        :output => full_path, # don't forget the extension!
      )

      _log_good "Saved to #{full_path}"
      _create_entity "Screenshot", {
        "name" => "#{target_uri}_screenshot",
        "uri" => "#{$intrigue_server_uri}/screenshots/#{filename}"
      }

      _log "Saved to... #{full_path}"

    rescue Screencap::Error => e
      _log_error "Unable to capture screenshot: #{e}"
    end
  end

  # Takes a netblock and returns a list of uris
  def scan_for_uris(to_scan, ports=[80,443,8080,8081,8443])

    ###
    ### SECURITY - sanity check to_scan
    ###

    # sanity check our ports
    ports.each{|x| raise "NO" unless x.kind_of? Integer}

    # Create a tempfile to store results
    temp_file = "#{Dir::tmpdir}/nmap_scan_#{rand(100000000)}.xml"

    # Check for IPv6
    nmap_options = ""
    nmap_options << "-6 " if to_scan =~ /:/

    # shell out to nmap and run the scan
    _log "Scanning #{to_scan} and storing in #{temp_file}"
    _log "NMap options: #{nmap_options}"
    nmap_string = "nmap #{to_scan} #{nmap_options} -P0 -p #{ports.join(",")} --min-parallelism 10 -oX #{temp_file}"
    _log "Running... #{nmap_string}"
    _unsafe_system(nmap_string)

    uris = []
    Nmap::XML.new(temp_file) do |xml|
      xml.each_host do |host|
        host.each_port do |port|

          # determine if this is an SSL application
          ssl = true if [443,8443].include?(port.number)
          protocol = ssl ? "https://" : "http://" # construct uri

          uri = "#{protocol}#{host.ip}:#{port.number}"

          if port.state == :open
            _log "Adding #{uri} to list"
            uris << uri
          end

        end
      end
    end

    _log "Returning #{uris} to scan"

  return uris
  end

end
end
