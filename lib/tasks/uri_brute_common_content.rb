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
        {:name => "user_list", :regex => "alpha_numeric_list", :default => [] }
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

    ###
    ### Get the default case (a page that doesn't exist)
    ###
    random_value = "#{rand(100000000)}"
    request_page_one = "doesntexist-#{random_value}"
    request_page_two = "def-#{random_value}-doesntexist"
    response = http_request :get,"#{uri}/#{request_page_one}"
    response2 = http_request :get,"#{uri}/#{request_page_two}"

    # check for sanity
    unless response && response2
      _log_error "Unable to connect to site!"
      return false
    end

    # check to make sure we don't just go down the rabbit hole
    # some pages print back our uri, so first remove that if it exists
    unless response.body.gsub(request_page_one,"") && response2.body.gsub(request_page_two,"")
      _log_error "Cowardly refusing to test - different responses on our missing page checks"
      return false
    end

    # Default to code
    missing_page_test = :code
    # But select based on the response to our random page check
    case response.code
      when "404"
        missing_page_test = :code
      when "200"
        missing_page_test = :content
        missing_page_content = response.body
      else
        missing_page_test = :code
        missing_page_code = response.code
    end

    # Create our queue of work from the checks in brute_list
    work_q = Queue.new
    brute_list.each do |item|
      item["check_paths"].each do |dir|
        request_uri = "#{uri}#{"/" unless uri[-1] == "/"}#{dir}"
        work_q << request_uri
      end
    end

    # Create a pool of worker threads to work on the queue
    workers = (0...opt_threads).map do
      Thread.new do
        begin
          while uri = work_q.pop(true)

            # Do the check
            results = check_uri_exists(request_uri, missing_page_test, missing_page_code, missing_page_content)

            # create a new entity for each one
            _create_entity "Uri", results

          end # end while
        rescue ThreadError
        end
      end
    end; "ok"
    workers.map(&:join); "ok"
  end # end run method


end
end
end
