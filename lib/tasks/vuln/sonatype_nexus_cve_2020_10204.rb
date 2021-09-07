module Intrigue
  module Task
  class SonatypeNexusCve202010204 < BaseTask

    def self.metadata
      {
        :name => "vuln/sonatype_nexus_cve_2020_10204",
        :pretty_name => "Vuln Check - Sonatype Nexus RCE (CVE-2020-10204)",
        :authors => ["jcran"],
        :identifiers => [{ "cve" =>  "CVE-2020-10204" }],
        :description => "Sonatype Nexus Repository before 3.21.2 allows Remote Code Execution.",
        :references => [
          "https://github.com/advisories/GHSA-8h56-v53h-5hhj",
          "https://support.sonatype.com/hc/en-us/articles/360044882533-CVE-2020-10199-Nexus-Repository-Manager-3-Remote-Code-Execution-2020-03-31",
          "https://medium.com/@prem2/nexus-repository-manger-3-rce-cve-2020-10204-el-injection-rce-blind-566d902c1616",
          "https://xpoc.pro/out-of-band-rce-via-el-injection/"
        ],
        :type => "vuln_check",
        :passive => false,
        :allowed_types => ["Uri"],
        :example_entities => [
          {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
        ],
        :allowed_options => [],
        :created_types => []
      }
    end

    ## Default method, subclasses must override this
    def run
      super

      require_enrichment

      ###
      ### Just check version, as this requires an autheenticated account to exploit
      ###

      # check our fingerprints for a version
      our_version = nil
      fp = _get_entity_detail("fingerprint")
      fp.each do |f|
        if f["product"] == "Nexus Repository Manager" && f["version"] != ""
          our_version = f["version"]
          break
        end
      end

      if our_version
        _log "Got version: #{our_version}"
      else
        _log_error "Unable to get version, failing"
        return
      end

      if ::Versionomy.parse(our_version) <= ::Versionomy.parse("3.21.1")
        _log_good "Vulnerable!"
        _create_linked_issue("sonatype_nexus_cve_2020_10204", {
          proof: {
            detected_version: our_version
          }
        })
        return
      end


      ###
      ### In the future, consider an actual exploit, if user creds are provided
      ###

      #uri = _get_entity_name
      #hostname = URI.parse(uri).hostname.to_s
      #csrf_token = "8d0c3bff-fe84-408e-a60d-c1c49eb07a17"
      #cookie = "NX-ANTI-CSRF-TOKEN=#{csrf_token}; Path=/"

      #headers = {
      #  "Host" => "#{hostname}",
      #  "Referer" => "#{uri}",
      #  "X-Nexus-UI" => "true",
      #  "X-Requested-With" => "XMLHttpRequest",
      #  "NX-ANTI-CSRF-TOKEN" => "#{csrf_token}",
      #  "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:73.0) Gecko/20100101 Firefox/73.0",
      #  "Accept" => "application/json, text/plain, */*",
      #  "Accept-Language" => "zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2",
      #  "Accept-Encoding" => "gzip, deflate",
      #  "Content-Type" => "application/json",
      #  "cookie" => "#{cookie}",
      #  "Origin" => "#{uri}",
      #  "Connection" => "close"
      #}

      # print headers
      #response = http_request :get, uri
      #response.each_header { |header| _log "Got header: #{header}" }

      #uri = "#{_get_entity_name}/service/extdirect"
      #body = '{"action":"coreui_User","method":"update","data":[{"userId":"anonymous","version":"1","firstName":"Anonymous","lastName":"User2","email":"anonymous@example.org","status":"active","roles":["$\\c{1337*1337"]}],"type":"rpc","tid":28}'

      #response = http_request(:post, uri, nil, headers, body)

      #if response.code == "200" && response.body_utf8 =~ /1787569/
      #  _create_linked_issue "sonatype_nexus_cve_2020_10204", {"proof" => response.body_utf8 }
      #else
      #  _log "Not vulnerable!"
      #  _log "Got response: #{response.code} #{response.body_utf8}"
      #end


    end

  end
  end
  end
