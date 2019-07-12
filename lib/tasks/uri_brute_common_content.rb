module Intrigue
module Task
class UriBruteCommonContent < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_brute_common_content",
      :pretty_name => "URI Brute Common Content",
      :authors => ["jcran", "@0xsauby"],
      :description => "Bruteforce common files and directories on a web server.",
      :references => [
        "https://www.owasp.org/index.php/Category:OWASP_DirBuster_Project",
        "https://github.com/0xsauby/yasuo",
        "https://github.com/intrigueio/intrigue-core/blob/develop/data/exploitable.json",
        "https://security.stackexchange.com/questions/79256/scan-all-possible-files-on-server-brute-force-filenames",
        "https://nmap.org/nsedoc/scripts/http-config-backup.html",
        "https://github.com/danielmiessler/SecLists"
      ],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "threads", :regex => "integer", :default => 1 },
        {:name => "user_list", :regex => "alpha_numeric_list", :default => [] },
        {:name => "create_url", :regex => "boolean", :default => false }
      ],
      :created_types => ["Uri"]
    }
  end


  def run
    super

    # TODO - integrate a simple default list:
    ## "admin, test, server-status, .svn, .git, wp-config.php, config.php, configuration.php, LocalSettings.php, mediawiki/LocalSettings.php, mt-config.cgi, mt-static/mt-config.cgi, settings.php, .htaccess, config.bak, config.php.bak, config.php~, #config.php#, config.php.save, .config.php.swp, config.php.swp, config.php.old"

    # Get options
    uri = _get_entity_name
    opt_threads = _get_option("threads")
    opt_create_url = _get_option("create_url")
    user_list = _get_option("user_list")

    # TODO - what's going on here? shouldn't this always be a string?
    # 21:43:09 WARN: NoMethodError: undefined method `split' for []:Array
    # 21:43:09 WARN: /Users/jcran/work/intrigue/projects/intrigue-core/lib/tasks/uri_brute.rb:34:in `run'
    user_list = user_list.split(",") unless user_list.kind_of? Array

    # Pull our list from a file if it's set
    if user_list.length > 0
      _log "Using custom list: #{user_list.to_s}"
      brute_list = user_list.map {|x| {"check_paths" => [x], "source" => "user", "check_name" => "user" }}
    else
      _log "Using default list from data/exploitable.json"
      brute_list = JSON.parse(File.read("#{$intrigue_basedir}/data/exploitable.json"))
    end

    # Create our queue of work from the checks in brute_list
    work_q = Queue.new
    brute_list.each do |item|
      item["check_paths"].each do |dir|
        request_path = "#{"/" unless uri[-1] == "/"}#{dir}"
        work_q << { path: request_path, regex: nil, severity: 5, status: "potential" }
      end
    end

    ## do the work 
    ##
    make_http_requests_from_queue(uri, work_q, opt_threads, opt_create_url)    

  end

end
end
end
