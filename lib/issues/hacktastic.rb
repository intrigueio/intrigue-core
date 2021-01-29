
module Intrigue
  module Issue
    class Hacktastic < BaseIssue

      def self.generate(instance_details={})
      {
        added: "2021-01-18",
        name: "hacktastic_shpendk",
        pretty_name: "Shpendk Hacktastic",
        identifiers: [{ type: "CVE", name: "CVE-2017-9506" }],
        severity: 4,
        status: "confirmed",
        category: "misconfiguration",
        description: "This server is exposing a sensitive path on an Apache Tomcat instance.",
        remediation: "Adjust access congrols on this server to remove access to this path.",
        affected_software: [
            { :vendor => "SolarWinds", :product => "Orion Platform" },
            { :vendor => "SolarWinds", :product => "Orion Core" }
        ],
        references: [
            { type: "description", uri: "https://cyber.dhs.gov/ed/21-01/" },
            { type: "description", uri: "https://www.zdnet.com/article/microsoft-fireeye-confirm-solarwinds-supply-chain-attack/" }
        ],
        authors: ["shpendk"]
      }.merge!(instance_details)
      end

    end
  end  
  
  module Task
    class Hacktastic < BaseIssueCheck 
    
    def self.check_metadata
      {
        allowed_types: ["Uri"],
        example_entities: [
            {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
        ],
        allowed_options: []
      }
    end

    def check
      # do the thing here 

      # run a nuclei 
      #run_nuclei 

      # call a simple version comparison 
      #check_inference 

      # our random ruby code
      _log "HACKTASTIC: #{_get_entity_name}"
    end

  end
end # end Module intrigue
end