module Intrigue
module Task
class UriBruteCreds < BaseTask

  include Intrigue::Task::Data
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_brute_creds",
      :pretty_name => "URI Bruteforce Credentials",
      :authors => ["jcran"],
      :description => "Bruteforce authentication for a given URI.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "user_list", :regex => "alpha_numeric_list", :default => [] }
      ],
      :created_types => ["Uri"]
    }
  end

  def run
    super

    # Get options
    uri = _get_entity_name
    opt_threads = _get_option("threads")
    user_list = _get_option("user_list")

    user_list = user_list.split(",") unless user_list.kind_of? Array

    # Pull our list from a file if it's set
    if user_list.length > 0
      brute_list = simple_web_creds
      brute_list.concat(user_list.map {|x| {:username => x.split(":").first, :password => x.split(":").last } })
    else
      brute_list = simple_web_creds
    end

    _log "Using list: #{brute_list}"

    # Default to code
    brute_list.each do |b|

      response = http_request(:get,uri, b)

      if response
        # But select based on the response to our random page check
        case response.code
        when "401"
          _log_error "Invalid credential: #{b}"
        when "403"
          _log_error "Invalid credential: #{b}"
        when "200"
          _log_good " !!! Valid credential: #{b}"
          _create_entity "Credential", {
            "name" => "Bruteforced Credential (#{b[:username]}) for #{uri}",
            "uri" => uri,
            "username" => "#{b[:username]}",
            "password" => "#{b[:password]}"
          }
        else
          _log_error "Invalid credential (code: #{response.code}): #{b}"
        end
      else
        _log_error "No response!"
      end

    end
  end

end
end
end
