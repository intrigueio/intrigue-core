module Intrigue
module Entity
class NetworkService < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "NetworkService",
      :description => "A Generic Network Service",
      :user_creatable => true
    }
  end

  def validate_entity
    name.match /[\w\d\.]+:\d{1,5}/
  end

  def detail_string

    out = ""

    # create fingerprint details string
    out = "#{short_fingerprint_string(details["fingerprint"])} | " if details["fingerprint"]
      
    out << "Port: #{details["service"]}"
  end

  def enrichment_tasks
    ["enrich/network_service"]
  end

  def scoped?
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)
  
  true
  end

  def scope_verification_list
    [
      { type_string: self.type_string, name: self.name },
      { type_string: "IpAddress", name: self.name.split(":").first }
    ]
  end

end
end
end
