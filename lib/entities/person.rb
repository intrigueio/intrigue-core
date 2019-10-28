module Intrigue
module Entity
class Person < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Person",
      :description => "A Person",
      :user_creatable => true,
      :example => "Bazooka Joe"
    }
  end

  def validate_entity
    name =~ /^[\w\s\d\.\-\_\&\;\:\,\@]+$/
  end

  def detail_string
    "#{details["origin"]}"
  end

end
end
end
