module Intrigue
module Entity
class Uri < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Uri",
      :description => "A Website or Webpage",
      :user_creatable => true
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

  def detail_string
    "#{details["stack"].to_a.join(" | ")}"
  end

end
end
end
