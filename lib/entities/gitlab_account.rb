module Intrigue
  module Entity
    class GitlabAccount < Intrigue::Core::Model::Entity
      def self.metadata
        {
          name: 'GitlabAccount',
          description: 'A Gitlab Account',
          user_creatable: true,
          example: 'intrigueio'
        }
      end

      def validate_entity
        # gitlab account names are 1-255 characters and contain dots, underscores and dashes but cannot start with them
        name.match(/^[^\-|_|\.][\w\-?\.?]{1,255}$/)
      end

      def enrichment_tasks
        ['enrich/gitlab_account']
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
