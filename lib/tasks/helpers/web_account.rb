require_relative 'web'

module Intrigue
module Task
module WebAccount

  def _create_normalized_webaccount(service_name, username, url, alias_entity=nil)
    _create_entity "WebAccount", {
      "name" => "#{service_name}: #{username}",
      "uri" => url,
      "username" => "#{username}",
      "service" => service_name
    }, alias_entity 
  end

end
end
end