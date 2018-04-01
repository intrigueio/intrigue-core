module Intrigue
module Entity
class Document < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Document",
      :description => "A Document (File)",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

  def detail_string
    details["content_type"] if details && details["content_type"]
  end

end
end
end
