module Intrigue
module Entity
class Domain < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Domain",
      :description => "A Top-Level Domain",
      :user_creatable => true
    }
  end

  def validate_entity
    name =~ /^[a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-\_]*[a-zA-Z0-9\-\_]\.*[A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-\_]*[A-Za-z\.]$/ #_dns_regex
  end

  def detail_string
    return "" unless details["resolutions"]
    details["resolutions"].each.group_by{|k| k["response_type"] }.map{|k,v| "#{k}: #{v.length}"}.join("| ")
  end

  def enrichment_tasks
    ["enrich/domain"]
  end

end
end
end
