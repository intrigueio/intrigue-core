module Intrigue
module Task
module Ident

  ###
  ### Use the issue factory to find vulnerasbility checks we can run
  ### and kick them off
  ###
  def run_vuln_checks_from_fingerprint(fingerprint, entity)

    all_checks = []
    project = entity.project

    fingerprint.each do |f|

      ### Get a list of actual vulnerability checks based on issues
      vendor_string = f["vendor"]
      product_string = f["product"]

      _log "Getting checks for #{vendor_string} #{product_string}"
      checks_to_be_run = Intrigue::Issue::IssueFactory.checks_for_vendor_product(vendor_string, product_string)

      _log "Appending login bruteforce checks for #{vendor_string} #{product_string}"
      checks_to_be_run << Intrigue::TaskFactory.checks_for_vendor_product(vendor_string, product_string)

      all_checks << checks_to_be_run
    end

    # handle nuclei, and cve checks here
    #
    all_checks.flatten.compact.uniq.each do |check|

      # if we want to pass check options based on some fingerprint crtieria
      check_options = []

      # get the scan result id ... TODO, ideally we'd track this.
      existing_scan_result_id = nil

      # start the task
      start_task("task_autoscheduled", project, existing_scan_result_id, check, entity, 1, check_options)
    end

  # return a list of checks
  all_checks.flatten.compact.uniq
  end

  def create_issues_from_fingerprint_tags(fingerprint, entity)

    return unless fingerprint && entity

    issues_to_create = []
    tags = []

    # iterate through the fingerprints and create
    # issues for each known tag
    fingerprint.each do |fp|
      next unless fp && fp["tags"]
      fp["tags"].each do |t|
        tags << fp["tags"]
        if  t.match(/^Admin Panel$/i)
          issues_to_create << ["exposed_admin_panel_unauthenticated", fp]
        elsif t.match(/^RDP$/i)
          issues_to_create << ["open_rdp_port", fp]
        elsif t.match(/^SMB$/i)
          issues_to_create << ["exposed_smb_service", fp]
        elsif t.match(/^Database$/i)
          issues_to_create << ["exposed_database_service", fp]
        elsif t.match(/^DefaultPage$/i)
          issues_to_create << ["default_web_server_page_exposed", fp]
        elsif t.match(/^FTP Server$/i) || t.match(/^TelnetServer/i)
          issues_to_create << ["weak_service_identified", fp]
        elsif t.match(/^SNMPServer$/i)
          issues_to_create << ["exposed_snmp_service", fp]
        elsif t.match(/^Printer$/i)
          issues_to_create << ["exposed_printer_control_panel", fp]
        elsif t.match(/^Webcam$/i)
          issues_to_create << ["exposed_webcam_interface", fp]
        end
      end
    end

    issues_to_create.each do |i|
      instance_specifics = i.last.merge({
        proof: "Entity fingerprint contains issue-mapped tag: #{tags.flatten.sort.uniq}" })
      _create_linked_issue i.first, instance_specifics, entity
    end

  end

  ###
  ### Parse out, and fingerprint the individual components
  ###
  def fingerprint_links(links, hostname)
    script_components = extract_and_fingerprint_links(links, hostname)

    ### Check for vulns in included scripts
    fingerprint = []
    if script_components.count > 0
      fingerprint.concat(add_vulns_by_cpe(script_components))
    end

  fingerprint
  end

  def extract_and_fingerprint_links(link_list, host)
    components = []
    link_list.each do |s|

      # skip anything that's not http
      next unless s.match(/^http/)

      begin
        uri = URI.parse(s)
      rescue URI::InvalidURIError
        @task_result.logger.log "Unable to parse improperly formatted URI: #{s}"
        next # unable to parse
      end

      next unless uri.host && uri.port && uri.scheme.match(/^http/)
      ###
      ### Determine who's hosting
      ###
      begin
        if uri.host.match(/#{host}/)
          host_location = "local"
        else
          host_location = "remote"
        end
      rescue URI::InvalidURIError
        host_location = "unknown"
      end

      ###
      ### Match it up with ident
      ###
      ident = Intrigue::Ident::Ident.new
      ident_matches = ident.fingerprint_uri(s, {'only-check-base-url': true })
      js_fp_matches = ident_matches["fingerprint"].select{|x| x["tags"] && x["tags"].include?("Javascript") }

      if js_fp_matches.count > 0
        js_fp_matches.each do |m|
          components << m.merge({"uri" => s, "relative_host" =>  host_location })
        end
      else
        # otherwise, we didnt find it, so just stick in a url withoout a name / version
        components << {"uri" => s, "relative_host" =>  host_location }
      end
    end

  components.compact
  end



  def fingerprint_url(url)
     ###
    ### But default to HTTP through each known port
    ###
    ident = Intrigue::Ident::Ident.new
    ident_matches = ident.fingerprint_uri(url) || {}

    # okay we failed
    return unless ident_matches

    # if we didnt fail, pull out the FP and match to vulns
    ident_fingerprints = ident_matches["fingerprint"] || []
    if ident_fingerprints.count > 0
      ident_fingerprints = add_vulns_by_cpe(ident_fingerprints)
    end

  ident_matches.merge({"fingerprint" => ident_fingerprints})
  end


end
end
end