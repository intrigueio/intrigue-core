module Intrigue
module Task
class CiscoSmartInstallScan < BaseTask

  def self.metadata
    {
      :name => "vuln/cisco_smart_install_scan",
      :pretty_name => "Vuln Check - Cisco Smart Install Scanner",
      :authors => ["jcran"],
      :identifiers => [{ "cve" =>  false }],
      :description => "Check for Cisoc Smart Install Misconfiguration",
      :references => [
        "http://blog.talosintelligence.com/2018/04/critical-infrastructure-at-risk.html",
        "https://github.com/Cisco-Talos/smi_check"
      ],
      :type => "vuln_scan",
      :passive => false,
      :allowed_types => ["NetBlock"],
      :example_entities => [
        {"type" => "NetBlock", "details" => {"name" => "10.0.0.0/8"}}
      ],
      :allowed_options => [
        {:name => "max_rate", :regex => "integer", :default => 1000 }
      ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    opt_max_rate = _get_option("max_rate")

    results = _masscan_netblock(@entity,[4786],[],opt_max_rate)
    _log_error "Invalid params" unless results

    results.each do |r|
      _log "Result: #{r}"

      # check to see if it's a smart install enabled device
      ip_entity = _create_entity "IpAddress", {"name" => r["ip_address"]}
      _create_network_service_entity(ip_entity,r["port"],r["protocol"],{})
    end

  end

end
end
end
