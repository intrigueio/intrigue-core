module Intrigue
module Entity
class Nameserver < Intrigue::Model::Entity

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "Nameserver",
      :description => "A DNS Nameserver",
      :user_creatable => true,
      :example => "ns1.intrigue.io"
    }
  end

  def validate_entity
    return ( name =~ ipv4_regex || name =~ ipv6_regex || name =~ dns_regex )
  end

  def enrichment_tasks
    ["enrich/nameserver"]
  end

    ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if self.seed
    return false if self.hidden # hit our blacklist so definitely false

    #
    # Check types we'll check for indicators of in-scope-ness
    #scope_check_entity_types = [ "Intrigue::Entity::Domain" ]

    #self.project.seeds.each do |s|
    #  return true if s.name =~ /#{parse_domain_name(self.name)}/i
    #end

    # check hidden on-demand
    return true if self.project.traversable_entity?(parse_domain_name(self.name), "Domain")

  # if we didnt match the above and we were asked, it's false 
  false
  end

end
end
end
