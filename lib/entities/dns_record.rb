module Intrigue
module Entity
class DnsRecord < Intrigue::Model::Entity
  
  def self.metadata
    {
      :name => "DnsRecord",
      :description => "A Dns Record",
      :user_creatable => true,
      :example => "test.intrigue.io"
    }
  end

  def validate_entity
    name =~ dns_regex
  end

  def detail_string
    return "" unless details["resolutions"]
    details["resolutions"].each.group_by{|k| k["response_type"] }.map{|k,v| "#{k}: #{v.length}"}.join("| ")
  end

  def enrichment_tasks
    ["enrich/dns_record"]
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if self.seed
    return false if self.hidden # hit our blacklist so definitely false

  # if we didnt match the above and we were asked, return whatever we got
  # during the creation process
  self.scoped
  end

end
end
end
