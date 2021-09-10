module Intrigue
  module Entity
    class GitlabProject < Intrigue::Core::Model::Entity
      include Intrigue::Task::Gitlab # in order to use gitlab helper method
      def self.metadata
        {
          name: 'GitlabProject',
          description: 'A Gitlab Project',
          user_creatable: true,
          example: 'https://gitlab.com/intrigueio/intrigue-core'
        }
      end

      def validate_entity
        parsed = parse_gitlab_uri(name, 'project')
        parsed.project
      end

      def enrichment_tasks
        ['enrich/gitlab_project']
      end

      def scoped?
        return scoped unless scoped.nil?
        return true if allow_list || project.allow_list_entity?(self)
        return false if deny_list || project.deny_list_entity?(self)

        true
      end
    end
  end
end
