module Intrigue
module Entity
class Mailserver < Intrigue::Core::Model::Entity

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
    return true if self.allow_list
    return false if self.deny_list

  # if we didnt match the above and we were asked, it's false 
  false
  end

end
end
end
