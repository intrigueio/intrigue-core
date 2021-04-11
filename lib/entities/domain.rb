module Intrigue
module Entity
class Domain < Intrigue::Core::Model::Entity


  def self.metadata
    {
      name: "Domain",
      description: "A Top-Level Domain",
      user_creatable: true,
      example: "intrigue.io"
    }
  end

  # gets called before entity is created
  def self.transform_before_save(name, details_hash)
    name = SimpleIDN.to_ascii(name)
    return name, details_hash
  end

  def validate_entity
    name.match dns_regex(true)
  end

  def detail_string
    return "" unless details["resolutions"]
    details["resolutions"].each.group_by{|k|
      k["response_type"] }.map{|k,v| "#{k}: #{v.length}"}.join(" | ")
  end

  def enrichment_tasks
    ["enrich/domain"]
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={})
    return scoped unless scoped.nil?
    return true if self.allow_list || self.project.allow_list_entity?(self)
    return false if self.deny_list || self.project.deny_list_entity?(self)

  # if we didnt match the above and we were asked, let's not allow it
  false
  end

end
end
end
