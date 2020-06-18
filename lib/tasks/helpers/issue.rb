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
  def _create_linked_issue(issue_type, instance_specifics={}, linked_entity=@entity)

    _log_good "Creating linked issue of type: #{issue_type}"

    issue_model_details = {  
      entity_id: linked_entity.id,
      task_result_id: @task_result.id,
      project_id: @project.id, 
      scoped: linked_entity.scoped,
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

  ###
  ### Generic finding coming from ident. 
  ###
  def _create_content_issue(uri, check)
    _create_linked_issue("content_issue", { uri: uri, check: check })
  end

  def _create_missing_cookie_attribute_http_only_issue(uri, cookie, severity=5)
    
    # skip this for anything other than hostnames 
    hostname = URI(uri).hostname
    return if hostname =~ ipv4_regex || hostname =~ /ipv6_regex/
    
    addtl_details = { cookie: cookie }
    _create_linked_issue("insecure_cookie_httponly_attribute", addtl_details)
  end

  def _create_missing_cookie_attribute_secure_issue(uri, cookie, severity=5)
    
    # skip this for anything other than hostnames 
    hostname = URI(uri).hostname
    return if hostname =~ ipv4_regex || hostname =~ /ipv6_regex/
    
    addtl_details = { cookie: cookie }
    _create_linked_issue("insecure_cookie_secure_attribute", addtl_details)
  end

  def _create_weak_cipher_issue(uri, accepted_connections)
    _create_linked_issue("weak_ssl_ciphers_enabled",{ accepted: accepted_connections})
  end

  def _create_deprecated_protocol_issue(uri, accepted_connections)
    _create_linked_issue("deprecated_ssl_protocol_detected",{ accepted: accepted_connections})
  end

  def _check_request_hosts_for_suspicious_request(uri, request_hosts)

    # don't flag on actual localhost
    return if uri =~ /:\/\/127\.0\.0\./
    return if uri =~ /:\/\/localhost/

    if  ( request_hosts.include?("localhost") ||
          request_hosts.include?("0.0.0.0") ||
          !request_hosts.select{|x| x =~ /^127\.\d\.\d\.\d$/ }.empty?)

        _create_linked_issue("suspicious_web_resource_requested",{ 
          requests: request_hosts,
          reason: "Localhost or otherwise unroutable IP address"
        })

      end

  end

  def _check_request_hosts_for_exernally_hosted_resources(uri, request_hosts, min_host_count=50)

    if  ( request_hosts.uniq.count >= min_host_count)
      addtl_details = { min_host_count: min_host_count, request_hosts: request_hosts }
      _create_linked_issue("gratuitous_external_resources_requested", addtl_details)
    end
    
  end

  def _check_requests_for_mixed_content(uri, requests)
    requests.each do |req|

      resource_url = req["url"]

      # skip data 
      return if uri =~ /^data:.*$/

      # skip this for anything other than hostnames 
      begin 
        hostname = URI(resource_url).hostname
      rescue URI::InvalidURIError => e 
        @task_result.logger.log_error "Unable to parse URI: #{resource_url}"
        return 
      end
      
      return if hostname =~ ipv4_regex || hostname =~ /ipv6_regex/

      if resource_url =~ /^http:.*$/ 
        _create_linked_issue("insecure_content_loaded", {
          uri: uri,
          insecure_resource_url: resource_url,
          request: req
        })
      end
    end
  end

  ###
  ### Network and Host oriented issues
  ###

  # RFC1918 DNS
  def _internal_system_exposed_via_dns
    _create_linked_issue("internal_system_exposed_via_dns", {
      resolutions: "#{@entity.aliases.map{|x| x.name}}",
      exposed_ports: @entity.details["ports"]
    })
  end

  # Development or Staging
  def _exposed_server_identified(regex, name=nil)
    exposed_name = name || @entity.name
    _create_linked_issue("development_system_identified", {
      matched_regex: "#{regex}",
      resolutions: "#{@entity.aliases.map{|x| x.name}}",
      exposed_ports: @entity.details["ports"]
    })
  end

  def _create_weak_service_issue(ip_address, port, proto, tcp)
    transport = tcp ? "TCP" : "UDP"
    _create_linked_issue("weak_service_identified", {
      ip_address: ip_address,
      port: port,
      proto: proto,
      transport: transport })
  end

end
end
end
