module Intrigue
  module Entity
    class GithubAccount < Intrigue::Core::Model::Entity
      def self.metadata
        {
          name: 'GithubAccount',
          description: 'A Github Account',
          user_creatable: true,
          example: 'https://github.com/intrigueio'
        }
      end

      def validate_entity
        name.match /^https:\/\/github.com\/[\w\-]{1,39}$/
      end

      def enrichment_tasks
        # to enrich github accounts, use enrich/github_account and prepend to array below
        ['gather_github_repositories']
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
