module Intrigue
  module Task
    class Gitleaks < BaseTask
      def self.metadata
        {
          name: 'gitleaks',
          pretty_name: 'Gitleaks',
          authors: ['Anas Ben Salah', 'zricethezav'],
          description: 'Gitleaks search potential leaks exposed secrets in a specific git repo.',
          references: ['https://github.com/zricethezav/gitleaks#readme'],
          type: 'discovery',
          passive: false,
          allowed_types: ['Uri'],
          example_entities: [{ 'type' => 'Uri', 'details' => { 'name' => 'https://github.com/my-insecure/repo' } }],
          allowed_options: [],
          created_types: ['GithubRepository', 'GithubAccount']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        uri = _get_entity_name

        # Verify URI matchs a git repository 
        github_regex = /(http[s]?:\/\/)github.com/
        gitlab_regex = /(http[s]?:\/\/)github.com/
        return unless  uri =~ github_regex || uri =~ gitlab_regex

        # Extract Git repository and Git account
        uri_path = URI(uri).path

        #gitaccount = uri_path[/([^\/\s]+)/,1]
        gitrepo = uri_path.match(/([^\/\s]+\/)(.*)/)

        # output file
        temp_file = "#{Dir::tmpdir}/gitleaks_#{rand(1000000000000)}.json"

        # task assumes gitleaks is in our path and properly configured
        _log "Starting Gitleaks on repo #{gitrepo}"
        command_string = "gitleaks -r #{uri} -v -o #{temp_file}"
        _unsafe_system command_string
        _log "Gitleaks finished on #{uri_path}!"

        # parse output
        begin
          output = JSON.parse(File.open(temp_file,'r').read)
        rescue Errno::ENOENT => e
          _log_error "No such file: #{temp_file}"
        rescue JSON::ParserError => e
          _log_error "Unable to parse: #{temp_file}"
        end

        # sanity check
        unless output
          _log_error 'No output, failing'
          return
        end

        # Create Git Repository entity
        _create_entity('GithubRepository', {
          'name' => gitrepo,
          'uri'  => uri
        })

        # Create linked issues for potential exposures 
        output.each do |d|
          _create_linked_issue('suspicious_commit', {
            source: d['leakURL'],
            proof: {
              line: d['line'],
              linneNumber: d['lineNumber'],
              offender: d['offender'],
              commit: d['commit'],
              file: d['file']
            },
            author: d['author'],
            email: d['email'],
            date: d['date'],
            tags: d['tags']
          })
        end

        # clean up
        begin
          File.delete(temp_file)
        rescue Errno::EPERM
          _log_error 'Unable to delete file'
        end
      end
    end
  end
end
