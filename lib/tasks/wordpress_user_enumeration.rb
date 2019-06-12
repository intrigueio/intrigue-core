module Intrigue
module Task
class WordpressUserEnumeration < BaseTask

  def self.metadata
    {
      :name => "wordpress_user_enumeration",
      :pretty_name => "Wordpress User Enumeration",
      :authors => ["jcran", "jgamblin"],
      :description => "If the target's running Wordpress, this'll enumerate the users",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  def run
    super

    uri = _get_entity_name

    begin
      body = http_get_body "#{uri}/wp-json/wp/v2/users"
      parsed = JSON.parse body 

      usernames = parsed.map{|x| x["name"] }
      _set_entity_detail("wordpress_users", usernames )

    rescue JSON::ParserError
      _log_error "Unable to parse!"
    end

  end # end run()

end
end
end
