module Intrigue
module Entity
class WebAccount < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "WebAccount",
      :description => "An account identified for a specific hosted service in the format \"service: username\" ",
      :user_creatable => true
    }
  end

  def validate_entity
    name.match /^[\w\d\.\-\(\)\\\/\_]+:\s?[\w\d\.\-\(\)\\\/\_]+$/ 
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
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)
  true
  end

end
end
end
