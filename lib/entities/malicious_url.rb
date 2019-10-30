module Intrigue
module Entity
class MaliciousUrl < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "MaliciousUrl",
      :description => "A link to a website or webpage known to be malicious",
      :user_creatable => true,
      :example => "https://terrible.com"
    }
  end

  def validate_entity
    name =~ /^http[s]?:\/\/.*$/
  end

  def detail_string
    "no detail string available"
  end

  def enrichment_tasks
    []
  end

end
end
end
