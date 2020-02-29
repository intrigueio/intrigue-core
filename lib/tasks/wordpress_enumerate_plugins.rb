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
      :allowed_options => [
        { :name => "use_extended_list", :regex => "boolean", :default => false },
        { :name => "threads", :regex => "integer", :default => 5 }
      ],
      :created_types => []
    }
  end

  def run
    super

    uri = _get_entity_name

    # First just get the easy stuff 
    _set_entity_detail("wordpress_plugins", get_wordpress_parsable_plugins(uri) )
    
    # Then, attempt to brute
    _set_entity_detail("wordpress_bruted_plugins", brute_wordpress_plugin_paths(uri) )

  end # end run()

  def brute_wordpress_plugin_paths(uri)

    if _get_option("use_extended_list")
      _log "Using extended list"
      file_path = "#{$intrigue_basedir}/data/tech/wordpress_plugins.list"
    else 
      _log "Using short list"
      file_path = "#{$intrigue_basedir}/data/tech/wordpress_plugins.short.list"
    end

    # add wordpress plugins list from a file
    work_q = Queue.new
    File.open(file_path,"r").each_line do |l|
      next if l =~ /^#/
      work_q.push({ path: "#{l.strip}/" , severity: 5,  body_regex: nil, status: "potential" })
      work_q.push({ path: "#{l.strip}/readme.txt" , severity: 5,  body_regex: /Contributors:/i, status: "confirmed" })
    end
    
    # then make the requests
    thread_count = _get_option("threads") || 5

    results = make_http_requests_from_queue(uri, work_q, thread_count, false, false) # always create an issue
    _log "Got matches: #{results}"
  
  results
  end

  def get_wordpress_parsable_plugins(uri)
    
    body = http_get_body "#{uri}/wp-json"
    begin
      parsed = JSON.parse body 
    rescue JSON::ParserError
      _log_error "Unable to parse!"
    end
   
    return nil unless parsed 

    plugins = (parsed["namespaces"] || []).uniq.map{|x| x.gsub("\\","") }
  end

end
end
end
