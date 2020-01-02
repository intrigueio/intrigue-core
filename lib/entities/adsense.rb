module Intrigue
module Entity
class Adsense < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Adsense",
      :description => "Google Adsense ID",
      :user_creatable => true,
      :example => "Literally any string in this format pub-{numbers}"
    }
  end

  def validate_entity
    name =~ /^pub-.\d.*.\d/
  end



end
end
end
