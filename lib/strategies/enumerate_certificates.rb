module Intrigue
module Strategy
  class EnumerateCertificates < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "enumerate_certificates",
        :pretty_name => "Grab SSL Certificate for every URI",
        :passive => true,
        :user_selectable => false,
        :authors => ["jcran"],
        :description => "This strategy grabs the certificate for every URI."
      }
    end

    def self.recurse(entity, task_result)
      if entity.type_string == "Uri"
        start_recursive_task(task_result,"uri_gather_ssl_certificate",entity, [
          {"name" => "parse_entities", "value" => false }
        ])
      end
    end

end
end
end
