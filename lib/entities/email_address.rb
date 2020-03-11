module Intrigue
module Entity
class EmailAddress < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "EmailAddress",
      :description => "An Email Address",
      :user_creatable => true,
      :example => "no-reply@intrigue.io"
    }
  end

  def validate_entity
    name =~ /[a-zA-Z0-9\.\_\%\+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,12}/
  end

  def detail_string
    details["origin"] if details && details["origin"]
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if self.seed
    return false if self.hidden

  # if we didnt match the above and we were asked, let's just allow it 
  true
  end


end
end
end
