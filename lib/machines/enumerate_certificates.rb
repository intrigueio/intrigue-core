module Intrigue
module Machine
  class EnumerateCertificates < Intrigue::Machine::Base

    def self.metadata
      {
        :name => "enumerate_certificates",
        :pretty_name => "Grab SSL Certificate for every URI",
        :passive => false,
        :user_selectable => false,
        :authors => ["jcran"],
        :description => "This machine grabs the certificate for every URI."
      }
    end

    def self.recurse(entity, task_result)
      
      if entity.type_string == "Uri"
      
        start_recursive_task(task_result,"uri_gather_ssl_certificate",entity, [
          {"name" => "parse_entities", "value" => false }
        ])
      
      elsif entity.type_string == "NetBlock"

        start_recursive_task(task_result,"masscan_scan",entity,[
          {"name"=> "tcp_ports", "value" => "80,443,8080"}], true)

      end
    
    end

end
end
end
