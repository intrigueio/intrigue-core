module Intrigue
  module Task
    class Gitleaks < BaseTask
      def self.metadata
        {
          name: 'gitleaks',
          pretty_name: 'Gitleaks',
          authors: ['maxim', 'Anas Ben Salah', 'zricethezav'],
          description: 'Gitleaks is a SAST tool for detecting hardcoded secrets like passwords, api keys, and tokens in git repos.',
          references: ['https://github.com/zricethezav/gitleaks#readme'],
          type: 'discovery',
          passive: false,
          allowed_types: ['Uri'],
          example_entities: [{ 'type' => 'Uri', 'details' => { 'name' => 'https://github.com/my-insecure/repo' } }],
          allowed_options: [
            { name: 'use_authentication', regex: 'boolean', default: true },
            { name: 'custom_keywords', regex: 'alpha_numeric_list', default: '' }
          ], # use authentication?
          created_types: ['GithubRepository']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        repo_uri = _get_entity_name
        custom_keywords = _get_option('custom_keywords').delete(' ').split(',')
        custom_config = create_custom_config(custom_keywords) unless custom_keywords.nil?

        access_token = retrieve_gh_access_token if _get_option('use_authentication')

        output_f = run_gitleaks(repo_uri, access_token, custom_config)
        issues = parse_output(output_f)

        return if issues.nil?

        _log_good "Found #{issues.size} suspicious commits."
        create_issue(issues)

        cleanup(output_f, custom_config)
      end

      def run_gitleaks(repo, access_token, config_file)
        access_token = '' if access_token.nil? # set to empty string as gitleaks will ignore it
        config_file = "#{$intrigue_basedir}/data/gitleaks.config" if config_file.nil?

        temp_file = "/tmp/#{SecureRandom.uuid}.json"
        _log "Running gitleaks on #{repo}"

        _unsafe_system("gitleaks -r #{repo} --report=#{temp_file} --access-token=#{access_token} --config-path=#{config_file}")

        temp_file
      end

      def parse_output(output_file)
        # parse output
        json_output = return_json_output(output_file)
        return nil if json_output.nil?

        results = json_output.map do |i|
          { 'commit_uri' => i['leakURL'], 'finding_type' => i['rule'], 'date' => i['date'] }
        end

        results
      end

      def return_json_output(output_file)
        begin
          parsed_output = JSON.parse(File.open(output_file).read)
          _log 'No suspicious issues were detected by gitleaks.' if parsed_output.nil?
        rescue Errno::ENOENT
          _log_error 'gitleaks failed to run; possible reasons: private repository without setting an acess token or non-existent repository.'
          nil
        rescue JSON::ParserError
          _log_error 'Unable to parse gitleaks output.'
          nil
        end

        parsed_output
      end

      def create_custom_config(keywords)
        temp_rule_file = "/tmp/#{SecureRandom.uuid}-rules.config"

        custom_rules = keywords.map { |k| replace_rule_template(k) }
        File.open(temp_rule_file, 'w') { |f| f.write(custom_rules.join("\n")) }

        temp_rule_file
      end

      def replace_rule_template(keyword)
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

      def create_issue(issue_h)
        _create_linked_issue('suspicious_commit', {
                               proof: issue_h
                             })
      end

      def cleanup(temp_file, config_temp_file)
        File.delete(temp_file)
        File.delete(config_temp_file) unless config_temp_file.nil?
      rescue Errno::EPERM
        _log_error 'Unable to delete gitleaks output.'
      end

      def retrieve_gh_access_token
        client = initialize_gh_client
        _get_task_config('github_access_token') if client
        # return access key since github client is valid meaning api key works
      end
    end
  end
end
