module Intrigue
module Entity
class Domain < Intrigue::Model::Entity
  include Intrigue::Task::Helper

  def self.metadata
    {
      :name => "Domain",
      :description => "A Top-Level Domain",
      :user_creatable => true
    }
  end

  def validate_entity
    name =~ /\w.*/ #_dns_regex
  end

  def primary
    false
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
