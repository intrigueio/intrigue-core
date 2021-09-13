module Intrigue
  module Task
    module Github

      def initialize_gh_client
        # the platform may try to pull the deprecated gitrob_access_token for legacy tasks
        # if that token doesn't exist, try pulling from the github_access_token
        access_token = access_token_exists('github_access_token')
        access_token ||= access_token_exists('gitrob_access_token')

        _log_error 'Github Access Token is not set in task config.' if access_token.nil?
        return if access_token.nil?

        _verify_gh_access_token(access_token)
      end

      def access_token_exists(type)
        _get_task_config(type)
      rescue MissingTaskConfigurationError
        nil
      end

      def create_gitleaks_custom_config(keywords)
        temp_rule_file = "/tmp/#{SecureRandom.uuid}-rules.gitleaks"

        custom_rules = keywords.map { |k| _replace_rule_template(k) }
        File.open(temp_rule_file, 'w') { |f| f.write(custom_rules.join("\n")) }

        temp_rule_file
      end

      # called in two tasks - thus warranting it a helper
      def create_github_repo_entity(repo_full_name)
        repo_full_name = "https://github.com/#{repo_full_name}" unless repo_full_name.include? 'https://github.com'
        _create_entity 'GithubRepository', {
          'name' => repo_full_name
        }
      end

      def extract_github_account_name(repo)
        repo.scan(/https:\/\/github\.com\/([\w|\-]+)\/?/i).flatten.first
      end

      def extract_full_repo_name(repo)
        repo.scan(/https:\/\/github\.com\/([\w|\-]+\/[\w|\-]+)/i).flatten.first
      end

      ### Single threaded version
      def run_gitleaks(repo, access_token, config_file)
        access_token = '' if access_token.nil? # set to empty string as gitleaks will ignore it
        config_file = "#{$intrigue_basedir}/data/gitleaks.config" if config_file.nil?

        temp_file = "/tmp/#{SecureRandom.uuid}.gitleaks"
        _log "Running gitleaks on #{repo}"

        _unsafe_system("gitleaks -r #{repo} --report=#{temp_file} --access-token=#{access_token} --config-path=#{config_file}")

        output = _parse_gitleaks_output(temp_file)

        output
      end

      # creates a single thread which is running gitleaks against the queue
      #  ... Use this helper if you want a multi-threaded run
      def threaded_gitleaks(repos_q, gitleaks_config, thread_count = 3)
        output = []
        workers = (0...thread_count).map do
          results = _run_gitleaks_thread(repos_q, output, _get_task_config('github_access_token'), gitleaks_config)
          [results]
        end
        workers.flatten.map(&:join)

        output
      end

      # create suspicious commit
      def create_suspicious_commit_issue(issue_h, source_commit)
        _create_linked_issue('suspicious_commit', {
                               status: 'potential',
                               proof: issue_h,
                               source: source_commit
                             })
      end

      private

      def _verify_gh_access_token(token)
        client = Octokit::Client.new(access_token: token, per_page: 100)
        begin
          client.user
        rescue Octokit::Unauthorized, Octokit::TooManyRequests
          _log_error 'Github Access Token invalid mostly likely due to invalid credentials.'
          return nil
        end

        # diable auto pagination
        client.auto_paginate = false

        { 'access_token' => token, 'client' => client }
      end

      def _parse_gitleaks_output(output_file)
        # parse output
        json_output = _return_gitleaks_json(output_file)
        return nil if json_output.nil?

        results = json_output.map do |i|
          { 'commit_uri' => i['leakURL'], 'finding_type' => i['rule'], 'date' => i['date'] }
        end

        results
      end

      # creates a single thread which is running gitleaks against the queue
      def _run_gitleaks_thread(input_q, output_q, access_token, config) # change the name of this method
        t = Thread.new do
          until input_q.empty?
            while repo = input_q.shift
              results = run_gitleaks(repo, access_token, config)
              next if results.nil?

              output_q << results
            end
          end
        end
        t
      end

      def _replace_rule_template(keyword)
        rule = <<-RULE
        [[rules]]
          description = "REPLACE_DESCRIPTION_HERE"
          regex = '''REPLACE_REGEX_HERE'''
        RULE

        replace_items = { 'REPLACE_DESCRIPTION_HERE' => "Custom Keyword: #{keyword}",
                          'REPLACE_REGEX_HERE' => Regexp.new(keyword).inspect[1...-1] }

        re = Regexp.new(replace_items.keys.map { |x| Regexp.escape(x) }.join('|'))
        rule.gsub!(re, replace_items)
      end

      def _return_gitleaks_json(output_file)
        begin
          parsed_output = JSON.parse(File.open(output_file).read)
          _log 'No suspicious issues were detected by gitleaks.' if parsed_output.nil?
        rescue Errno::ENOENT
          _log_error 'gitleaks tasked failed to run; most likely due to insufficient access or non-existent repository.'
          nil
        rescue JSON::ParserError
          _log_error 'Unable to parse gitleaks output.'
          nil
        end

        parsed_output
      end

      def remove_gitleaks_temp_files
        temporary_files = Dir['/tmp/*.gitleaks']
        begin
          temporary_files.each { |temp| File.delete(temp) }
        rescue Errno::ENOENT
          _log_error 'Unable to delete gitleaks output.'
        end
      end
    end
  end
end
