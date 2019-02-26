module Intrigue
module Task
class UriBruteFocusedContent < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_brute_focused_content",
      :pretty_name => "URI Brute Focused Content",
      :authors => ["jcran"],
      :description => "Check for pages specific to the site's technology." + 
        "Supported Tech: ASP.net, Coldfusion, Tomcat",
      :references => [
        ""
      ],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "threads", :regex => "integer", :default => 1 },
        {:name => "create_url", :regex => "boolean", :default => false }
      ],
      :created_types => ["Uri"]
    }
  end

  def is_product?(product_name)
    return false unless _get_entity_detail("fingerprint")
    out = _get_entity_detail("fingerprint").any?{|v| v['product'] == product_name if v['product']}
    _log_good "Matched URI to Product: #{product_name} !" if out
  out
  end

  def run
    super

    uri = _get_entity_name
    opt_threads = _get_option("threads") 
    opt_create_url = _get_option("create_url")

    always_list = [ 
      { path: "/api", :regex => nil },
      { path: "/.git", :regex => /<h1>Index of/ },
      { path: "/.hg", :regex => /<h1>Index of/ },
      { path: "/.svn", :regex => /<h1>Index of/ },
      { path: "/.bzr", :regex => /<h1>Index of/ },
      #{ path: "/.csv", :regex => /<h1>Index of/ },
      #{ path: "/.bak",  :regex => /<h1>Index of/ },
      { path: "/crossdomain.xml", :regex => /<cross-domain-policy/ },
      { path: "/clientaccesspolicy.xml", :regex => /<access-policy/ },
      #{ path: "/sitemap.xml", :regex => nil },
      { path: "/portal", :regex => nil },
      { path: "/admin", :regex => nil },
      { path: "/test", :regex => nil },
      { path: "/server-status", :regex => / <title>Apache Status/ }
    ]
      # "/WS_FTP.LOG", "/ws_ftp.log"

    # technology specifics 
    asp_net_list = [
      { path: "/elmah.axd", :regex => nil },
      { path: "/web.config", :regex => nil },
      { path: "/Trace.axd", :regex => /Microsoft \.NET Framework Version/ }
    ]
    # /Trace.axd - 

    coldfusion_list = [
      { path: "/CFIDE",  :regex => nil },
      { path: "CFIDE/administrator/enter.cfm",  :regex => nil }
    ] # TODO see metasploit for more ideas here

    tomcat_list = [ 
      { path: '/status',  :regex => nil },
      { path: '/web-console', :regex => nil },
      { path: '/jmx-console', :regex => nil },
      { path: '/admin-console',  :regex => nil },
      { path: '/manager/html', :regex => nil },
      { path: '/tomcat/manager/html', :regex => nil },
      { path: '/host-manager/html', :regex => nil },
      { path: '/server-manager/html', :regex => nil },
      { path: '/web-console/Invoker', :regex => nil },
      { path: '/jmx-console/HtmlAdaptor', :regex => nil },
      { path: '/invoker/JMXInvokerServlet', :regex => nil }
    ]

    wordpress_list = [
      { path: '/wp-admin',  :regex => nil },
    ]

    ###
    ### Get the default case (a page that doesn't exist)
    ###
    random_value = "#{rand(100000000)}"
    request_page_one = "doesntexist-#{random_value}"
    request_page_two = "def-#{random_value}-doesntexist"
    response = http_request :get,"#{uri}/#{request_page_one}"
    response_two = http_request :get,"#{uri}/#{request_page_two}"

    # check for sanity
    unless response && response_two
      _log_error "Unable to connect to site!"
      return false
    end

    # check to make sure we don't just go down the rabbit hole
    # some pages print back our uri, so first remove that if it exists
    unless response.body.gsub(request_page_one,"") && response_two.body.gsub(request_page_two,"")
      _log_error "Cowardly refusing to test - different responses on our missing page checks"
      return false
    end

    # Default to code
    missing_page_test = :code
    # But select based on the response to our random page check
    case response.code
      when "404"
        _log "Using CODE as missing page test, missing page will give a 404"
        missing_page_test = :code
      when "200"
        _log "Using CONTENT as missing page test, missing page will give a 200"
        missing_page_test = :content
        missing_page_content = response.body
      else
        _log "Defaulting to CODE as missing page test, missing page will give a #{response.code}"
        missing_page_test = :code
        missing_page_code = response.code
    end
    ##########################

    # Create our queue of work from the checks in brute_list
    work_q = Queue.new
    
    #  first handle our specific here (more likely to be interesting)
    asp_net_list.each { |x| work_q.push x } if is_product?("ASP.NET") || is_product?("ASP.NET MVC")
    coldfusion_list.each { |x| work_q.push x } if is_product? "Coldfusion"  
    tomcat_list.each { |x| work_q.push x } if is_product? "Tomcat" 
    wordpress_list.each { |x| work_q.push x } if is_product? "Wordpress" 

    # then add our "always" stuff:
    always_list.each { |x| work_q.push x }

    # Create a pool of worker threads to work on the queue
    workers = (0...opt_threads).map do
      Thread.new do
        begin
          while request_details = work_q.pop(true)

            request_uri = "#{uri}#{request_details[:path]}"
            positive_regex = request_details[:regex]

            # Do the check
            result = check_uri_exists(request_uri, missing_page_test, missing_page_code, missing_page_content, positive_regex)

            if result 

              # create a new entity for each one if we specified that 
              _create_entity("Uri", result) if  opt_create_url
              
              _create_issue({
                name: "Discovered Content at #{result[:name]}",
                type: "discovered_content",
                severity: 5,
                status: "potential",
                description: "Page was found with a code #{result[:response_code]} by url_brute_focused_content at #{result[:name]}",
                details: result.except!(:name)
              })
            end

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
