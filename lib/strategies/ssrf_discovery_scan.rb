module Intrigue
module Strategy
  class SsrfDiscoveryScan < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "ssrf_discovery_scan",
        :pretty_name => "SSRF Discovery Scan",
        :passive => true,
        :authors => ["jcran"],
        :description => "This strategy takes a netblock and tests all scanned hosts for SSRF."
      }
    end

    def self.recurse(entity, task_result)
      if entity.type_string == "Netblock"
        start_recursive_task(task_result,"masscan_scan",entity,[
          {"name"=> "tcp_ports", "value" => "80,443" },
          {"name"=> "max_rate", "value" => "2000" }
        ])
      elsif entity.type_string == "Uri"
        start_recursive_task(task_result,"vuln/ssrf_proxy_host_header",entity, [
          {"name" => "target_environment", "value" => "aws,local" }
        ])
      end
    end

end
end
end
