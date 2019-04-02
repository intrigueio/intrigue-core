module Intrigue
module Machine
  class SsrfDiscoveryScan < Intrigue::Machine::Base

    def self.metadata
      {
        :name => "ssrf_discovery_scan",
        :pretty_name => "SSRF Discovery Scan",
        :passive => false,
        :user_selectable => true,
        :authors => ["jcran"],
        :description => "This machine takes a netblock and tests all scanned hosts for SSRF."
      }
    end

    def self.recurse(entity, task_result)

      if entity.type_string == "NetBlock"
        start_recursive_task(task_result,"masscan_scan",entity,[
          {"name"=> "tcp_ports", "value" => "80,443,8080" },
          {"name"=> "max_rate", "value" => "3000" }
        ])

      elsif entity.type_string == "Uri"

        ec2_host = "ec2-54-205-88-180.compute-1.amazonaws.com"
        responder_uri = "http://#{ec2_host}:8888/"

        #start_recursive_task(task_result,"vuln/ssrf_brute_parameters",entity, [
        #  {"name" => "ssrf_target_uri", "value" => responder_uri }
        #])

        #start_recursive_task(task_result,"vuln/ssrf_brute_headers",entity, [
        #  {"name" => "ssrf_target_uri", "value" => responder_uri }
        #])

        start_recursive_task(task_result,"vuln/ssrf_proxy_host_header",entity, [
          {"name" => "target_environment", "value" => "aws,local" },
          {"name" => "ssrf_target_uri", "value" => responder_uri }
        ])

      end
    end

end
end
end
