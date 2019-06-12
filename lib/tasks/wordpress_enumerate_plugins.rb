module Intrigue
module Task
class WordpressEnumeratePlugins < BaseTask

  def self.metadata
    {
      :name => "wordpress_enumerate_plugins",
      :pretty_name => "Wordpress Enumerate Plugins",
      :authors => ["jcran"],
      :description => "If the target's running Wordpress, this'll enumerate the plugins",
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
      body = http_get_body "#{uri}/wp-json"
      parsed = JSON.parse body 

      plugins = (parsed["namespaces"] || []).uniq.map{|x| x.gsub("\\","") }

      _set_entity_detail("wordpress_plugins", plugins )

    rescue JSON::ParserError
      _log_error "Unable to parse!"
    end

  end # end run()

end
end
end
