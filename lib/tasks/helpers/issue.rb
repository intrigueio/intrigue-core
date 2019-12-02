module Intrigue
module Task
module Issue

  ###
  ### Generic helper method to create issues
  ###
  def _create_issue(details)
    _notify("Sev #{details[:severity]}!```#{details[:name]}```") if details[:severity] <= 3

    hash = details.merge({ entity_id: @entity.id,
                           task_result_id: @task_result.id,
                           project_id: @project.id })

    _log_good "Creating issue with name: #{details[:name]}"
    issue = Intrigue::Model::Issue.create(_encode_hash(hash))
  end

  ###
  ### DNS / Email issues
  ###
  def _create_dmarc_issues(mx_records, dmarc_record)

    # if we can't accept mail, no point in continuing
    return unless mx_records.count > 0

    if !dmarc_record
      _create_issue({
        name: "Missing DMARC Configuration",
        type: "missing_dmarc_configuration",
        severity: 4,
        status: "confirmed",
        description: "Domains that are configured to send email should implement one or more forms " +
          "of email authentication to verify that an email is actually from the domain it claims it is from. " +
          "Configuring a DMARC record provides the receiving mail server with the information needed to " +
          "evaluate messages that claim to be from the domain, and it is one of the most important steps " +
          "that can be taken to improve email deliverability.",
        references: [
          "https://www.sparkpost.com/resources/email-explained/dmarc-explained/",
          "https://www.sonicwall.com/support/knowledge-base/what-is-a-dmarc-record-and-how-do-i-create-it-on-dns-server/170504796167071/"
        ],
        details: {
          mx_records: mx_records,
          dmarc_record: dmarc_record
        }
      })
    end

  end

  ###
  ### Host oriented issues
  ###

  # Development or Staging
  def _exposed_server_identified(regex, name=nil, type="Development")

    exposed_name = name || @entity.name

    _create_issue({
      name: "#{type} System Identified",
      type: "#{type}_system_identified".downcase,
      severity: 5,
      status: "potential",
      description: "A system was identified that may be part of a #{type.downcase} " +
      "effort. Typically these systems should not be exposed to the internet. " +
      "Resolutions: #{@entity.aliases.map{|x| x.name}}",
      details: {
        matched_regex: "#{regex}",
        resolutions: "#{@entity.aliases.map{|x| x.name}}"
      }
    })
  end


  def _create_weak_service_issue(ip_address, port, proto, tcp)
    transport = tcp ? "TCP" : "UDP"
    _create_issue({
      name: "Weak Service Identified: #{proto} on #{port}",
      type: "weak_service_identified",
      severity: 4,
      status: "confirmed",
      description: "A service known to be weak and have more modern alternatives " +
      "was identified: #{proto} on #{ip_address}:#{port}/#{transport}",
      details: {
        ip_address: ip_address,
        port: port,
        proto: proto,
        transport: transport }
    })
  end

  ###
  ### Application oriented issues
  ###

   def _create_hijackable_subdomain_issue type, uri, status
      _create_issue({
        name: "Subdomain Hijacking Detected",
        type: "subdomain_hijack_detected",
        severity: 2,
        status: status,
        description:  "This uri #{uri} appears to be unclaimed on a third party host, meaning," +
                      " there's a DNS record at (#{uri}) that points to #{type}, but it" +
                      " appears to be unclaimed and you should be able to register it with" +
                      " the host, effectively 'hijacking' the domain.",
        details: {
          uri: uri,
          type: type
        }
      })
  end

  def _create_content_issue(uri, check)
    _create_issue({
      name: "Content Issue Discovered: #{check["name"]}",
      type: "#{check["name"].downcase.gsub(" ","_")}",
      severity: 4, # todo...
      status: "confirmed",
      description: "This server had a content issue: #{check["name"]}.",
      references: [],
      details: {
        uri: uri,
        check: check
      }
    })
  end

  def _create_missing_cookie_attribute_http_only_issue(uri, cookie, severity=5)
    _create_issue({
      name: "Insecure cookie detected: missing 'httpOnly' attribute",
      type: "insecure_cookie_detected",
      severity: severity,
      status: "confirmed",
      description: "A cookie was identified without the 'httpOnly' cookie attribute on #{uri}",
      references: [],
      details: {
        uri: uri,
        cookie: cookie
      }
    })
  end

  def _create_missing_cookie_attribute_secure_issue(uri, cookie, severity=5)
    _create_issue({
      name: "Insecure cookie detected: missing 'secure' attribute",
      type: "insecure_cookie_detected",
      severity: severity,
      status: "confirmed",
      description: "A cookie was identified without the 'secure' cookie attribute on #{uri}",
      references: [],
      details: {
        uri: uri,
        cookie: cookie
      }
    })
  end

  def _create_weak_cipher_issue(uri, accepted_connections)
    _create_issue({
      name: "Weak ciphers enabled",
      type: "weak_cipher_suite_detected",
      severity: 5,
      status: "confirmed",
      description: "This server is configured to allow a known-weak cipher suite on #{uri}",
      #recommendation: "Disable the weak ciphers.",
      references: [
        "https://thycotic.com/company/blog/2014/05/16/ssl-beyond-the-basics-part-2-ciphers/"
      ],
      details: {
        uri: uri,
        allowed: accepted_connections
      }
    })
  end

  def _create_deprecated_protocol_issue(uri, accepted_connections)
    _create_issue({
      name: "Deprecated protocol enabled",
      type: "deprecated_protocol_detected",
      severity: 5,
      status: "confirmed",
      description: "This server is configured to allow a deprecated ssl / tls protocol on #{uri}",
      #recommendation: "Disable the protocol, ensure support for the latest version.",
      references: [
        "https://tools.ietf.org/id/draft-moriarty-tls-oldversions-diediedie-00.html"
      ],
      details: {
        uri: uri,
        allowed: accepted_connections
      }
    })
  end

  def _check_request_hosts_for_suspicious_request(uri, request_hosts)

    if  ( request_hosts.include?("localhost") ||
          request_hosts.include?("0.0.0.0") ||
          !request_hosts.select{|x| x =~ /^127\.\d\.\d\.\d$/ }.empty?)

        _create_issue({
          name: "Suspicious Resource Requested on #{uri}",
          type: "suspcious_resource_requested",
          severity: 2,
          status: "confirmed",
          description: "When a browser requested the resource(s) located at #{uri}, a suspicious request was made.",
          #recommendation: "Verify if the host has been infected with malware and clean it.",
          references: [],
          details: {
            uri: uri,
            request_hosts: request_hosts
          }
        })

      end

  end


end
end
end
