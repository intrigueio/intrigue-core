module Intrigue
  module Entity
    class GitlabProject < Intrigue::Core::Model::Entity
      def self.metadata
        {
          name: 'GitlabProject',
          description: 'A Gitlab Project',
          user_creatable: true,
          example: 'intrigueio/intrigue-core'
        }
      end

      def validate_entity
        # same regex as account name however project name can start with a dot or underscore but not a dash
        name.match(/^[^\-|_|\.][\w\-?\.?]{1,255}\/[^\-][\w\-?\.?]{1,255}$/)
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
