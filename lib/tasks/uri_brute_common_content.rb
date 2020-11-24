module Intrigue
module Task
class UriBruteCommonContent < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_brute_common_content",
      :pretty_name => "URI Brute Common Content",
      :authors => ["jcran", "@0xsauby"],
      :description => "Bruteforce common files and directories on a web server. Note that this does not " + 
        "have a regex per check like uri_brute_generic_content",
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
        {:name => "use_file", :regex => "boolean", :default => false },
        # note that the brute_file has a specific format as shown in exploitable.json
        {:name => "brute_file", :regex => "filename", :default => "exploitable.json" },
        {:name => "create_url", :regex => "boolean", :default => false }
      ],
      :created_types => ["Uri"]
    }
  end


  def run
    super

    # Get options
    uri = _get_entity_name
    opt_threads = _get_option("threads")
    opt_create_url = _get_option("create_url")
    use_file = _get_option("use_file")
    brute_file = _get_option("brute_file")
    # get user list 
    user_list = _get_option("user_list")
    user_list = user_list.split(",") unless user_list.kind_of? Array

    # default list 
    default_list = "admin, test, server-status, .svn, .git, wp-config.php, config.php, configuration.php, LocalSettings.php, mediawiki/LocalSettings.php, mt-config.cgi, mt-static/mt-config.cgi, settings.php, .htaccess, config.bak, config.php.bak, config.php~, #config.php#, config.php.save, .config.php.swp, config.php.swp, config.php.old, .env"

    # Pull our list from a file if it's set
    if user_list.length > 0
      _log "Using custom list: #{user_list.to_s}"
      brute_list = user_list.map {|x| {"check_paths" => [x], "source" => "user", "check_name" => "user" }}
    elsif use_file
      _log "Using default list from data/exploitable-lite.json"
      brute_list = JSON.parse(File.read("#{$intrigue_basedir}/data/exploitable-lite.json"))
    else 
      brute_list = default_list
    end

    # Create our queue of work from the checks in brute_list
    work_q = Queue.new
    brute_list.each do |item|
      item["check_paths"].each do |dir|
        request_path = "#{"/" unless uri[-1] == "/"}#{dir}"
        work_q << { path: request_path, regex: nil, severity: 3, status: "potential" }
      end
    end

    ## do the work 
    ##
    make_http_requests_from_queue(uri, work_q, opt_threads, opt_create_url)    

  end

end
end
end
