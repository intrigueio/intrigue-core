module Intrigue
module Task
module VulnCheck

  def vendor?(fingerprint, vendor_name)
    matches_fingerprint_metadata?(fingerprint, vendor_name, 'vendor')
  end

  # fingerprint is an array of fps, product name is a string
  def is_product?(fingerprint, product_name)
    matches_fingerprint_metadata?(fingerprint, product_name, 'product')
  end

  def tag?(fingerprint, tag)
    return false unless fingerprint

    out = fingerprint.any? { |v| (v['tags']).to_s.include?(tag) if v['tags'] }
    _log_good "Matched tag: #{tag} !" if out
    out
  end

  def matches_fingerprint_metadata?(fingerprint, value_to_match, type)
    return false unless fingerprint

    out = fingerprint.any? { |v| (v[type]).to_s.match(/#{value_to_match}/i) if v[type] }
    _log_good "Matched fingerprint to #{type}: #{value_to_match} !" if out
    out
  end

  # function to compare version_a with version_b according to given operator.
  # will try to parse both parameters with versionomy. if parsing fails, it will compare them as string literals.
  def compare_versions_by_operator(version_a, version_b, operator)

    # try to parse via versionomy
    begin
      parsed_a = Versionomy.parse(version_a.scan(/\d\.?+/).join(''))
      parsed_b = Versionomy.parse(version_b.scan(/\d\.?+/).join(''))
    rescue Versionomy::Errors::ParseError
      # rescue will reassign the string values to compare as string literals
      #puts "DEBUG - Versionomy parsing failed for '#{version_a}' and '#{version_b}'. Falling back to string comparison" # debug
      parsed_a = version_a
      parsed_b = version_b
    end

    # perform comparison based on operator
    result = false
    if operator == "="
      result = parsed_a == parsed_b
    elsif operator == "<="
      result = parsed_a <= parsed_b
    elsif operator == "<"
      result = parsed_a < parsed_b
    elsif operator == ">"
      result = parsed_a > parsed_b
    elsif operator == ">="
      result = parsed_a >= parsed_b
    else
      result = parsed_a == parsed_b
    end

    result
  end

  # this helper function runs a nuclei template
  # templates are automatically loaded from data/nuclei-templates directory
  def run_nuclei_template(uri, template)
    # run ruclei with entity name and template
    _log "Running #{template} against #{uri}"
    begin
      ruclei = Ruclei::Ruclei.new
      ruclei.load_template("#{$intrigue_basedir}/data/nuclei-templates/#{template}.yaml")
      res = ruclei.run(uri)
      return { proof: res.template_info } unless res.nil?
    rescue Ruclei::Exceptions::MissingTemplateError # cannot find template
      _log_error 'ERROR: Cannot find template at specified path.'
    rescue Ruclei::Exceptions::InvalidTemplateError
      _log_error 'ERROR: Specified template does not appear to be in YAML format.'
    end

  nil
  end

  def run_nuclei_template_from_string(uri, template_string)
    # run ruclei with entity name and template
    _log "Running template against #{uri}"
    begin
      ruclei = Ruclei::Ruclei.new
      ruclei.parse_template template_string
      res = ruclei.run(uri)
      return { proof: res.template_info } unless res.nil?
    rescue Ruclei::Exceptions::InvalidTemplateError
      _log_error 'ERROR: Specified template does not appear to be in YAML format.'
    end

  nil
  end


  def get_version_for_vendor_product(entity, vendor, product)
    fingerprints = entity.get_detail("fingerprint")
    return nil unless fingerprints

    version = nil
    fingerprints.each do |f|
      if f["vendor"] == vendor && f["product"] == product && f["version"] != "" && f["version"] != nil
        version = f["version"]
        break
      end
    end

    version

  end

  def get_update_for_vendor_product(entity, vendor, product)
    fingerprints = entity.get_detail("fingerprint")
    return nil unless fingerprints

    version_update = nil
    fingerprints.each do |f|
      if f["vendor"] == vendor && f["product"] == product && f["update"] != "" && f["update"] != nil
        version_update = f["update"]
        break
      end
    end

    version_update

  end

  def fingerprint_to_inference_issues(fingerprint)
    fingerprint.each do |fp|
      next unless fp["vulns"]
      fp["vulns"].each do |vuln|
        # get and create the issue here
        issue_metadata = Intrigue::Issue::IssueFactory.get_issue_by_cve_identifier(vuln["cve"])
        next unless issue_metadata

        # if we have an issue who has that cve as an identifiger, run the check task
        task_name = issue_metadata[:task] || issue_metadata[:name]
        start_task("task_autoscheduled", @project, @task_result.scan_result_id, task_name, @entity, 1)
      end
    end
  end

end
end
end