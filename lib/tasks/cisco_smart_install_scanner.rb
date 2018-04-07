module Intrigue
module Task
class CiscoSmartInstallScanner < BaseTask

  include Intrigue::Task::Scanner

  def self.metadata
    {
      :name => "cisco_smart_install_scan",
      :pretty_name => "Cisco Smart Install Scanner",
      :authors => ["jcran"],
      :description => "Check for Smart Install",
      :references => [
        "http://blog.talosintelligence.com/2018/04/critical-infrastructure-at-risk.html"
      ],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["NetBlock"],
      :example_entities => [
        {"type" => "NetBlock", "details" => {"name" => "10.0.0.0/8"}}
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    results = _masscan_netblock(@entity,[4786],[])

    _log_error "Invalid params" unless results

    results.each do |r|
      _log "Result: #{r}"
      _create_entity "IpAddress", {"name" => r["ip_address"]}
    end

  end

end
end
end
