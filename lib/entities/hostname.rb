module Intrigue
  module Entity
  class Hostname < Intrigue::Core::Model::Entity

    include Intrigue::Task::Dns

    def self.metadata
      {
        name: "Hostname",
        description: "A Hostname, unassociated with a Domain. Typically an internal, sometimes-routable, hostname",
        user_creatable: true,
        example: "Web-pool-001"
      }
    end

    # gets called before entity is created

    def validate_entity
      name.match hostname_regex(true)
    end

    ###
    ### SCOPING
    ###
    def scoped?(conditions={})
      return scoped unless scoped.nil?
      return true if self.allow_list || self.project.allow_list_entity?(self)
      return false if self.deny_list || self.project.deny_list_entity?(self)

    # if we didnt match the above and we were asked, default to false
    true
    end

    def scope_verification_list
      [
        { type_string: self.type_string, name: self.name },
        { type_string: "Domain", name: parse_domain_name(self.name) }
      ]
    end

  end
  end
  end
