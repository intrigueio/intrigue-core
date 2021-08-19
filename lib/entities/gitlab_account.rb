module Intrigue
  module Entity
    class GitlabAccount < Intrigue::Core::Model::Entity
      def self.metadata
        {
          name: 'GitlabAccount',
          description: 'A Gitlab Account',
          user_creatable: true,
          example: 'https://gitlab.com/intrigueio'
        }
      end

      def validate_entity
        # match generic uri as gitlab instances can be self-hosted...
        name.match(/^https?:\/\/.*$/)
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
