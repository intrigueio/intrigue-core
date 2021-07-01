module Intrigue
  module Task
    module Github
      def initialize_gh_client
        begin
          access_token = _get_task_config('github_access_token')
        rescue MissingTaskConfigurationError
          _log 'Github Access Token is not set in task_config.'
          _log 'Please note this severely limits the results due to rate limiting.'
          return nil
        end

        verify_gh_access_token(access_token) # returns client if valid else nil
      end

      def verify_gh_access_token(token)
        client = Octokit::Client.new(access_token: token)
        begin
          client.user
        rescue Octokit::Unauthorized, Octokit::TooManyRequests
          _log_error 'Github Access Token invalid either due to invalid credentials or rate limiting reached; defaulting to unauthenticated.'
          return nil
        end
        client
      end

      def create_gitleaks_custom_config(keywords)
        temp_rule_file = "/tmp/#{SecureRandom.uuid}-rules.gitleaks"

        custom_rules = keywords.map { |k| _replace_rule_template(k) }
        File.open(temp_rule_file, 'w') { |f| f.write(custom_rules.join("\n")) }

        temp_rule_file
      end

      def _replace_rule_template(keyword)
        rule = <<-RULE
        [[rules]]
          description = "REPLACE_DESCRIPTION_HERE"
          regex = '''REPLACE_REGEX_HERE'''
        RULE

        replace_items = { 'REPLACE_DESCRIPTION_HERE' => "Custom Rule: #{keyword}",
                          'REPLACE_REGEX_HERE' => Regexp.new(keyword).inspect[1...-1] }

        re = Regexp.new(replace_items.keys.map { |x| Regexp.escape(x) }.join('|'))
        rule.gsub!(re, replace_items)
      end

      def run_gitleaks(repo, access_token, config_file)
        access_token = '' if access_token.nil? # set to empty string as gitleaks will ignore it
        config_file = "#{$intrigue_basedir}/data/gitleaks.config" if config_file.nil?

        temp_file = "/tmp/#{SecureRandom.uuid}.gitleaks"
        _log "Running gitleaks on #{repo}"

        _unsafe_system("gitleaks -r #{repo} --report=#{temp_file} --access-token=#{access_token} --config-path=#{config_file}")

        output = parse_gitleaks_output(temp_file)
        remove_gitleaks_temp_files

        output
      end

      def parse_gitleaks_output(output_file)
        # parse output
        json_output = _return_gitleaks_json(output_file)
        return nil if json_output.nil?

        results = json_output.map do |i|
          { 'commit_uri' => i['leakURL'], 'finding_type' => i['rule'], 'date' => i['date'] }
        end

        results
      end

      def remove_gitleaks_temp_files
        temporary_files = Dir['/tmp/*.gitleaks']
        begin
          temporary_files.each { |temp| File.delete(temp) }
        rescue Errno::ENOENT
          _log_error 'Unable to delete gitleaks output.'
        end
      end

      def _return_gitleaks_json(output_file)
        begin
          parsed_output = JSON.parse(File.open(output_file).read)
          _log 'No suspicious issues were detected by gitleaks.' if parsed_output.nil?
        rescue Errno::ENOENT
          _log_error 'gitleaks failed to run; possible reasons: private repository without setting an access token or non-existent repository.'
          nil
        rescue JSON::ParserError
          _log_error 'Unable to parse gitleaks output.'
          nil
        end

        parsed_output
      end

      def create_suspicious_commit_issue(issue_h)
        _create_linked_issue('suspicious_commit', {
                               proof: issue_h
                             })
      end

    end
  end
end
