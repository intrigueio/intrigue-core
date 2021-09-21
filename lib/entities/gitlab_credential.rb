module Intrigue
  module Entity
    class GitlabCredential < Intrigue::Core::Model::Entity
      def self.metadata
        {
          name: 'GitlabCredential',
          description: 'Gitlab Credential',
          sensitive: true
        }
      end

      def validate_entity
        sensitive_details['gitlab_host'] && sensitive_details['gitlab_access_token']
      end

      def scoped?
        return true if scoped
        return true if allow_list || project.allow_list_entity?(self)
        return false if deny_list || project.deny_list_entity?(self)

        true # otherwise just default to true
      end
    end
  end
end
