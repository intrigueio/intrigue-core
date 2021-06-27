module Intrigue
module Issue
  class MicrosoftExchangeHafniumCompromisedWebshell < BaseIssue
    def self.generate(instance_details={})
    {
      added: "2021-03-10",
      name: "microsoft_exchange_hafnium_compromised_webshell",
      pretty_name: "Microsoft Exchange Hafnium Compromised Webshell",
      identifiers: [
      ],
      severity: 1,
      status: "potential",
      category: "compromise",
      description: "A webshell was found related to a known compromise",
      remediation: "Inspect the server for compromise",
      affected_software: [
        { :vendor => "Microsoft", :product => "Exchange Server" }
      ],
      references: [
        { type: "description", uri: "https://github.com/PwnDefend/Exchange-RCE-Detect-Hafnium/blob/main/honeypot_shell_list.txt" },
        { type: "remediation", uri: "https://www.bleepingcomputer.com/news/security/microsofts-msert-tool-now-finds-web-shells-from-exchange-server-attacks/"},
        { type: "remediation", uri: "https://github.com/microsoft/CSS-Exchange/tree/main/Security"},
        { type: "threat_intel", uri: "https://www.bleepingcomputer.com/news/security/microsofts-msert-tool-now-finds-web-shells-from-exchange-server-attacks/"},
        { type: "threat_intel", uri: "https://github.com/PwnDefend/Exchange-RCE-Detect-Hafnium/blob/main/honeypot_shell_list.txt"},
        { type: "threat_intel", uri: "https://redcanary.com/blog/microsoft-exchange-attacks/"},
        { type: "threat_intel", uri: "https://gist.github.com/JohnHammond/0b4a45cad4f4ed3324939d72dc599883"},
        { type: "threat_intel", uri: "https://www.bankinfosecurity.com/at-least-10-apt-groups-exploiting-exchange-flaws-a-16166"},
        { type: "threat_intel", uri: "https://www.welivesecurity.com/2021/03/10/exchange-servers-under-siege-10-apt-groups/"},
        { type: "threat_intel", uri: "https://www.shadowserver.org/news/shadowserver-special-report-exchange-scanning-5/"},
        { type: "threat_intel", uri: "https://github.com/cert-lv/exchange_webshell_detection/blob/main/detect_webshells.ps1"},
      ],
      authors: ["jcran", "pwndefend"]
    }.merge!(instance_details)
    end

  end
end


module Task
  class MicrosoftExchangeHafniumCompromisedWebshell < BaseCheck
    def self.check_metadata
      {
        allowed_types: ["Uri"],
        example_entities: [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
        allowed_options: []
      }
    end

    def check
      # first, ensure we're fingerprinted
      require_enrichment

      known_webshell_paths = <<-eos
/aspnet_client/supp0rt.aspx
/aspnet_client/discover.aspx
/aspnet_client/shell.aspx
/aspnet_client/help.aspx
/aspnet_client/HttpProxy.aspx
/aspnet_client/0QWYSEXe.aspx
/aspnet_client/system_web/error.aspx
/aspnet_client/OutlookEN.aspx
/aspnet_client/sol.aspx
/aspnet_client/aspnettest.aspx
/aspnet_client/shellex.aspx
/aspnet_client/error_page.aspx
/aspnet_client/aspnet_client.aspx
/aspnet_client/iispage.aspx
/aspnet_client/system_web/log.aspx
/aspnet_client/load.aspx
eos

      # default value for the check response
      out = false

      # first test that we can get something
      contents = http_get_body "#{_get_entity_name}"
      _log_error "failing, unable to get a response" unless contents

      # get a missing page, and sha the dom
      benign_contents = http_get_body "#{_get_entity_name}/aspnet_client/#{rand(10000000)}.aspx"
      benign_content_sha = Digest::SHA1.hexdigest(html_dom_to_string(benign_contents))

      # check all paths for a non-error response
      known_webshell_paths.split("\n").each do |webshell_path|
        _log "Getting: #{webshell_path}"

        full_path = "#{_get_entity_name}#{webshell_path}"

        # get the body and do the same thing as above
        contents = http_get_body full_path
        our_sha = Digest::SHA1.hexdigest(html_dom_to_string(contents))

        ###

        if contents =~ /OAB \(Default Web Site\)/

          out = construct_positive_match(full_path, contents, benign_contents, false)

        else # rely on heuristics

          # now check them
          four_oh_four_content = /Please review the following URL/
          if our_sha != benign_content_sha && !contents =~ four_oh_four_content
            _log "Odd contents for #{full_path}!, flagging"
            out = construct_positive_match(full_path, contents, benign_contents, true)
          else
            _log "Got same content for missing page, probably okay"
          end

        end

      end

    out
    end

    def construct_positive_match(full_path, contents, benign_contents, heuristic_match)
      confidence_str = heuristic_match ? "confirmed" : "potential"
      out = {
        confidence: confidence_str,
        url: full_path,
        heuristic_match: heuristic_match,
        contents: contents,
        benign_contents: benign_contents,
        details: "Check diff of contents vs benign contents" }
    end
  end
end

end