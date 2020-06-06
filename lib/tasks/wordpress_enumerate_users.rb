module Intrigue
module Task
class WordpressEnumerateUsers < BaseTask

  def self.metadata
    {
      :name => "wordpress_enumerate_users",
      :pretty_name => "Wordpress Enumerate Users",
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
      return nil unless parsed
      
      if parsed.kind_of? Hash
        if parsed["code"] == "rest_no_route"
          _log_error "No route available to enumerate users"
          return nil 
        elsif parsed["code"]== "rest_user_cannot_view"
          _log_good "No permission to view"
          return nil 
        elsif parsed["code"]
          _log "Got code: #{parsed["code"]}"
          return nil
        else 
          _log_error "Unknown error"
          _log "Response: #{parsed.to_json}"
        end
      end

      # create users
      parsed.each do |u| 
        p = _create_entity "Person", { 
          "known_usernames" => ["#{u["slug"]}"],
          "name" => u["name"], 
          "uri" => u["link"] } if u["name"] =~ /\s/

        _create_normalized_webaccount("wordpress", u["slug"], u["link"], p)
      end

      # save on the entity
      usernames = parsed.map{|x| x["name"] }.uniq
      _set_entity_detail("wordpress_users", usernames )

    rescue JSON::ParserError
      _log_error "Unable to parse!"
    end

  end # end run()

end
end
end
