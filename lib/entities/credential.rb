module Intrigue
module Entity
class Credential < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Credential",
      :description => "Login credential"
    }
  end

  def validate_content
    @name =~ /^.*/ &&
    @details["username"].to_s =~ /^.*$/ &&
    @details["password"].to_s =~ /^.*$/ &&
    @details["uri"].to_s =~ /^.*$/
  end

end
end
end
