module Intrigue
module Entity
class WebAccount < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "WebAccount",
      :description => "An account identified for a specific hosted service in the format \"service: username\" ",
      :user_creatable => true
    }
  end

  def validate_entity
    name =~ /^\w+:\s?\w+$/ 
  end

  def transform!
    
    username = details["hidden_original"].split(":").last.strip
    service_name = details["hidden_original"].split(":").first.strip

    # force a space 
    self.name = "#{service_name}: #{username}"
    save_changes

    # grab the username / service
    set_details(
      { "name" => "#{service_name}: #{username}",
        "hidden_original" => "#{service_name}: #{username}".downcase,
        "username" => username,
        "service" => service_name })

    save_changes

  true
  end

  
  def scoped?
    return true if self.seed
    return false if self.hidden
  
  true
  end

end
end
end
