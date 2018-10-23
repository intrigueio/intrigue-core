module Intrigue
module Entity
class Nameserver < Intrigue::Model::Entity
  include Intrigue::Task::Helper

  def self.metadata
    {
      :name => "Nameserver",
      :description => "A DNS Nameserver",
      :user_creatable => true
    }
  end

  def validate_entity
    name =~ /\w.*/ #_dns_regex
  end
  
  def enrichment_tasks
    ["enrich/nameserver"]
  end

end
end
end
