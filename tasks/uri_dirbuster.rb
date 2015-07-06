class UriDirbuster  < BaseTask

  include Task::Web

  def metadata
    { :version => "1.0",
      :name => "uri_dirbuster",
      :pretty_name => "URI Dirbuster",
      :authors => ["jcran"],
      :description => "Bruteforce directories on a web server",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [
        {:type => "Uri", :attributes => {:name => "http://intrigue.io"}}
      ],
      :allowed_options => [
        # https://github.com/danielmiessler/SecLists/blob/master/vulns/apache.txt
        {:name => "brute_list", :type => "String", :regex => "alpha_numeric_list", :default =>
          [
            ".htaccess",".htpasswd",".meta",".web","access.log","access_log","admin","about",
            "administrator","awstats.pl","cfappman","cfdocs","cgi","cgi-bin","cgi-pub", "cgi-script",
            "clients","company","cpanel","dummy","error","error.log","error_log","forums",
            "global.inc","guest","guestbook","help","htdocs","httpd","httpd.pid","icons",
            "iisadmin","inc","inc/config.php","index.html","index.html~","index.html.bak",
            "lists","login","logs","mambo","manual","phf","php.ini","phpinfo.php",
            "printenv","profile.php","public","scripts","search","server-info",
            "servlet","server-status","services","status","test","test-cgi","tiki",
            "tmp","tsweb","trace.axd","webmail","wp-admin","x.aspx?aspxerrorpath=",
            "~bin", "~ftp","~nobody","~root", "_vti_bin"
          ]
        }
      ],
      :created_types => ["Uri"]
    }
  end

  def run
    super

    # Get the uri
    uri = _get_entity_attribute("name")

    ###
    ### Get the default case (a page that doesn't exist)
    ###
    response = http_get "#{uri}/#{rand(100000000)}"

    return @task_log.error "Unable to connect to site" unless response

    # Default to code
    missing_page_test = :code
    # But select based on the response
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

    puts "Missing Page Test: #{missing_page_test}"

    brute_list = _get_option "brute_list"
    brute_list = brute_list.split(",") if brute_list.kind_of? String
    
    brute_list.each do |dir|

      ## Construct the URI and make the request
      request_uri = "#{uri}/#{dir}"
      response = http_get request_uri

      #@task_log.log "Attempting #{request_uri}"

      next unless response

      ## If we are able to guess based on the code, we're super lucky!
      if missing_page_test == :code

        case response.code
          when "404"
            @task_log.log "404 on #{request_uri}"
          when "200"
            @task_log.good "200! Creating a page for #{request_uri}"
            _create_entity "Uri", :name => request_uri
          when "500"
            @task_log.good "500 error! Creating a page for #{request_uri}"
            _create_entity "Uri", :name => request_uri, :content => "#{response.body}"
          when missing_page_code
            @task_log.log "Got code: #{response.code}. Same as missing page code. Skipping"
          else
            @task_log.error "Don't know this response code? #{response.code} (#{request_uri})"
        end

      ## Otherwise, let's guess based on the content. Does this page look
      ## like a missing page?
      elsif missing_page_test == :content

        if response.body == missing_page_content
          @task_log.log "#{request_uri} looks like a missing page"
        else
          @task_log.log "#{request_uri} looks like a new page"
          _create_entity "Uri", :name => request_uri
        end

      end
    end

  end

end
