module Intrigue
module Task
class WpredpressEnumerateLeakedLogs < BaseTask

  def self.metadata
    {
      :name => "wordpress_enumerate_leaked_logs",
      :pretty_name => "Wordpress Enumerate Leaked Logs",
      :authors => ["jcran", "gehaxelt"],
      :description => "If the target's running Wordpress, this'll enumerate known leaked logfiles",
      :references => [ "https://blog.detectify.com/2020/02/26/gehaxelt-how-wordpress-plugins-leak-sensitive-information-without-you-noticing/"],
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
    
    # Then, attempt to brute
    _set_entity_detail("wordpress_bruted_log_paths", brute_wordpress_log_paths(uri) )

  end # end run()

  def brute_wordpress_log_paths(uri)

    known_paths = [
      "/wp-content/debug.log",
      "/wp-content/all-in-one-seo-pack.log",
      "/wp-content/uploads/mc4wp-debug.log",
      "/wp-content/uploads/wp-google-maps/error_log.txt",
      "/wp-content/plugins/ewww-image-optimizer/debug.log",
      "/wp-content/plugins/all-in-one-wp-migration/storage/error.log",
      "/wp-content/plugins/all-in-one-wp-migration/storage/import.log",
      "/wp-content/plugins/all-in-one-wp-migration/storage/export.log"
    ]

    # add wordpress plugins list from a file
    work_q = Queue.new
    known_paths.each do |p|
      next if p =~ /^#/
      _log "Wordpress known leaked log: #{p.strip}"
      work_q.push({ issue_type: "wordpress_leaked_log", path: "#{p.strip}" , severity: 3,  body_regex: nil, status: "potential" })
    end
    
    # then make the requests
    results = make_http_requests_from_queue(uri, work_q, thread_count=1, false, false) # always create an issue
    _log "Got matches: #{results}"
  
  results
  end

end
end
end
