module Intrigue
  module Entity
  class Mailserver < Intrigue::Model::Entity
  
    include Intrigue::Task::Dns
  
    def self.metadata
      {
        :name => "Mailserver",
        :description => "A Mailserver (MX)",
        :user_creatable => true,
        :example => "ns1.intrigue.io"
      }
    end
  
    def validate_entity
      return ( name =~ ipv4_regex || name =~ ipv6_regex || name =~ dns_regex )
    end
  
    def enrichment_tasks
      ["enrich/mailserver"]
    end
  
      ###
    ### SCOPING
    ###
    def scoped?(conditions={}) 
      return true if self.seed
      return false if self.hidden # hit our blacklist so definitely false
  
      # check hidden on-demand
      return true if self.project.traversable_entity?(parse_domain_name(self.name), "Domain")
  
    # if we didnt match the above and we were asked, it's false 
    false
    end
  
  end
  end
  end
  