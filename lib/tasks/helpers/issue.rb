module Intrigue
module Task
module Issue

  ###
  ### DEPRECATED!!!! Generic helper method to create issues
  ###
  def _create_issue(issue_hash)
    puts "DEPRECATED METHOD (_create_issue) called on #{issue_hash}"

    issue = issue_hash.merge({  entity_id: @entity.id,
                                scoped: @entity.scoped,
                                task_result_id: @task_result.id,
                                project_id: @project.id })

    _notify("CI Sev #{issue[:severity]}!```#{issue[:name]}```") if issue[:severity] <= 3

    # adjust naming per new schema
    temp_name = issue[:type]
    temp_pretty_name = issue[:name]

    # copy values into the detailss
    issue[:details][:description] = issue[:description]
    issue[:details][:references] = issue[:references]
    issue[:details][:category] = issue[:category]
    issue[:details][:status] = issue[:status]
    issue[:details][:severity] = issue[:severity]
    issue[:details][:pretty_name] = temp_pretty_name
    issue[:details][:name] = temp_name

    _log_good "Creating issue: #{temp_pretty_name}"
  Intrigue::Model::Issue.create(_encode_hash(issue))
  end

  def _linkable_issue_exists(issue_type)
    Intrigue::Issue::IssueFactory.include?(issue_type)
  end

  ### USE THIS GOING FORWARD
  def _create_linked_issue(issue_type, instance_specifics={})

    _log_good "Creating linked issue of type: #{issue_type}"

    issue_model_details = {  
      entity_id: @entity.id,
      task_result_id: @task_result.id,
      project_id: @project.id, 
      scoped: @entity.scoped,
    }
    
    issue = Intrigue::Issue::IssueFactory.create_instance_by_type(
      issue_type, issue_model_details, _encode_hash(instance_specifics))
  
    # Notify 
    _notify("LI Sev #{issue[:severity]}!```#{issue[:name]}```") if issue[:severity] <= 3

  issue 
  end

  ###
  ### DNS / Email issues
  ###
  def _create_dmarc_issues(mx_records, dmarc_record)

    # if we can't accept mail, no point in continuing
    return unless mx_records.count > 0

    if !dmarc_record
      _create_linked_issue "missing_dmarc_policy", { mx_records: mx_records, dmarc_record: dmarc_record }
    end

  end
  
  ###
  ### Application oriented issues
  ###

  def _create_content_issue(uri, check)
    _create_issue({
      name: "Content Issue Discovered: #{check["name"]}",
      type: "#{check["name"].downcase.gsub(" ","_")}",
      category: "application",
      severity: 4, # todo...
      source: "self",
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
      category: "application",
      source: "self",
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
      category: "application",
      source: "self",
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
      category: "application",
      severity: 5,
      source: "self",
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
      category: "application",
      severity: 5,
      source: "self",
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

    # don't flag on actual localhost
    return if uri =~ /:\/\/127\.0\.0\./
    return if uri =~ /:\/\/localhost/

    if  ( request_hosts.include?("localhost") ||
          request_hosts.include?("0.0.0.0") ||
          !request_hosts.select{|x| x =~ /^127\.\d\.\d\.\d$/ }.empty?)

      _create_issue({
        name: "Suspicious Resource Requested on #{uri}",
        type: "suspicious_resource_requested",
        category: "application",
        severity: 2,
        source: "self",
        status: "confirmed",
        description: "When a browser requested the resource(s) located at #{uri}, a suspicious request was made.",
        references: [],
        details: {
          uri: uri,
          request_hosts: request_hosts
        }
      })

      end

  end

  def _check_request_hosts_for_exernally_hosted_resources(uri, request_hosts, min_host_count=50)

    if  ( request_hosts.uniq.count >= min_host_count)
      _create_issue({
        name: "Large Number of Externally Hosted Resources",
        type: "large_number_of_externally_hosted_resources",
        category: "application",
        severity: 5,
        source: "self",
        status: "confirmed",
        description: "When a browser requested the resource located at #{uri}, a large number" +
        " of connections (#{request_hosts.count}) to unique hosts were made. In itself, this may" +
        " not be a security problem, but can introduce more attack surface than necessary, and is" +
        " indicative of poor security hygiene, as well as slow load times for a service." ,
        references: [],
        details: {
          min_host_count: min_host_count,
          uri: uri,
          request_hosts: request_hosts
        }
      })

    end
  end

  def _check_requests_for_mixed_content(uri, requests)
    requests.each do |req|

      resource_url = req["url"]

      if resource_url =~ /^http:.*$/ 
        _create_issue({
          name: "Insecure content loaded by page",
          type: "insecure_content",
          category: "application",
          severity: 4,
          source: "self",
          status: "confirmed",
          description: "When a browser requested the resource located at #{uri}, a resource was" +
          " requested at (#{resource_url}) over HTTP. This resource could be intercepted by a malicious" +
          " user and they may be able to take control of the information on the page.",
          #recommendation: "Verify if the host has been infected with malware and clean it.",
          references: ["https://developers.google.com/web/fundamentals/security/prevent-mixed-content/what-is-mixed-content"],
          details: {
            uri: uri,
            resource_url: resource_url,
            request: req
          }
        })
      end
    end
  end

  ###
  ### Network and Host oriented issues
  ###

  # Development or Staging
  def _exposed_server_identified(regex, name=nil, type="Development")

    exposed_name = name || @entity.name

    _create_issue({
      name: "#{type} System Identified",
      type: "#{type}_system_identified".downcase,
      category: "network",
      severity: 5,
      source: "dns",
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
      category: "network",
      source: "self",
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

end
end
end
