module Intrigue
module Task
class UriBrute < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_brute",
      :pretty_name => "URI Bruteforce",
      :authors => ["jcran", "@0xsauby"],
      :description => "Bruteforce common files and directories on a web server.",
      :references => [
        "https://www.owasp.org/index.php/Category:OWASP_DirBuster_Project",
        "https://github.com/0xsauby/yasuo",
        "https://github.com/intrigueio/intrigue-core/blob/develop/data/exploitable.json",
        "https://security.stackexchange.com/questions/79256/scan-all-possible-files-on-server-brute-force-filenames",
        "https://nmap.org/nsedoc/scripts/http-config-backup.html"
      ],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "threads", :type => "Integer", :regex => "integer", :default => 1 },
        {:name => "user_list", :type => "String", :regex => "alpha_numeric_list", :default => [] }
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
    response = http_request :get,"#{uri}/#{rand(100000000)}"

    unless response
      _log_error "Unable to connect to site"
      return false
    end

    # Default to code
    missing_page_test = :code
    # But select based on the response to our random page check
    case response.code
      when "404"
        @missing_page_test = :code
      when "200"
        @missing_page_test = :content
        @missing_page_content = response.body
      else
        @missing_page_test = :code
        @missing_page_code = response.code
    end

    # Log our method

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
            check_uri uri

          end # end while
        rescue ThreadError
        end
      end
    end; "ok"
    workers.map(&:join); "ok"
  end # end run

  def check_uri(request_uri)

    _log "Attempting #{request_uri}"
    response = http_request :get, request_uri
    return false unless response

    # try again if we got a blank page (some WAFs seem to do this?)
    if response.body = ""
      10.times do
        _log "Re-attemping #{request_uri}... verifying we should really have a blank page"
        response = http_request :get, request_uri
        next unless response
        break if response.body != ""
      end
    end

    # make sure we have a valid response
    return false unless response

    # always check for content...
    ["404", "forbidden"].each do |s|
      if (response.body =~ /#{s}/ )
        _log "Skipping #{request_uri}, contains a missing page string: #{s}"
        return false
      end
    end

    # always check code
    if (response.code == "400" || response.code == "401" || response.code == "403" || response.code == "404" || response.code == "500")
      _log "Skipping #{request_uri} based on code: #{response.code}"
      return false
    end

    ## If we are able to guess based on the code, we're super lucky!
    if @missing_page_test == :code
      case response.code
        when "200"
          _log_good "Clean 200! Creating a page for #{request_uri}"
          _create_entity "Uri",
            "name" => request_uri,
            "uri" => request_uri,
            "response_code" => response.code,
            "brute_response_body" => response.body
        when @missing_page_code
          _log "Got code: #{response.code}. Same as missing page code. Skipping"
        else
          _log "Flagging #{request_uri} because of response code #{response.code}!"
          _create_entity "Uri",
            "name" => request_uri,
            "uri" => request_uri,
            "response_code" => response.code,
            "brute_response_body" => response.body
      end

    ## Otherwise, let's guess based on the content. Does this page look
    ## like a missing page?
    elsif @missing_page_test == :content
      if response.body[0..100] == @missing_page_content[0..100]
        _log "Skipping #{request_uri} based on page content"
      else
        _log "Flagging #{request_uri} because of content!"
        _create_entity "Uri",
          "name" => request_uri,
          "uri" => request_uri,
          "response_code" => response.code,
          "brute_response_body" => response.body
      end
    end

  true
  end

end
end
end
