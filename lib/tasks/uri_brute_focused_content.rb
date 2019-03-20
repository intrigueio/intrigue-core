module Intrigue
module Task
class UriBruteFocusedContent < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_brute_focused_content",
      :pretty_name => "URI Brute Focused Content",
      :authors => ["jcran"],
      :description => "Check for juicy content based on the site's technology stack." + 
        " Supported Tech: ASP.net, Coldfusion, PHP, Sharepoint, Tomcat, Wordpress" + 
        " (Some pages can be parsed for additional entities, select the parse_content" + 
        " option if you'd like this to be done.)",      
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "threads", regex: "integer", :default => 1 },
        {:name => "create_url", regex: "boolean", :default => false },
        {:name => "parse_content", regex: "boolean", :default => false },
        {:name => "check_generic_content", regex: "boolean", :default => false }
      ],
      :created_types => ["Uri"]
    }
  end

  def is_product?(product_name)
    return false unless _get_entity_detail("fingerprint")
    out = _get_entity_detail("fingerprint").any?{|v| v['product'] =~ /#{product_name}/ if v['product']}
    _log_good "Matched URI to Product: #{product_name} !" if out
  out
  end

  def sleep_until_enriched
    entity_enriched = @entity.enriched?
    cycles = 30 
    until entity_enriched || cycles == 0
      _log "Waiting 10s for entity to be enriched... (#{cycles-=1} / 60)"
        sleep 10
      entity_enriched = Intrigue::Model::Entity.first(:id => @entity.id).enriched?
    end
  end

  def run
    super

    sleep_until_enriched

    uri = _get_entity_name
    opt_threads = _get_option("threads") 
    opt_create_url = _get_option("create_url")
    opt_parse_content = _get_option("parse_content") # TODO, not implemented today
    opt_generic_content = _get_option("check_generic_content") 

    generic_list = [ 
      { path: "/api", regex: nil },
      { path: "/.git", severity: 3, regex: /<h1>Index of/ },
      { path: "/.hg", severity: 3, regex: /<h1>Index of/ },
      { path: "/.svn", severity: 3, regex: /<h1>Index of/ },
      { path: "/.bzr", severity: 3, regex: /<h1>Index of/ },
      #{ path: "/.csv", regex: /<h1>Index of/ },
      #{ path: "/.bak", regex: /<h1>Index of/ },
      { path: "/crossdomain.xml", regex: /\<cross-domain-policy/, severity: 6, status: "confirmed"}, #tighten regex?
      { path: "/clientaccesspolicy.xml", regex: /\<access-policy/, severity: 6, status: "confirmed"}, #tighten regex?
      { path: "/portal", regex: nil },
      { path: "/admin", regex: nil },
      { path: "/test", regex: nil },
      { path: "/server-status", severity: 4, regex: /\<title\>Apache Status/, status: "confirmed" }
    ]

    # technology specifics 
    apache_list = [
      { path: "/.htaccess", regex: /AuthName/, status: "confirmed" },
      { path: "/.htaccess.bak", regex: /AuthName/, status: "confirmed" },
      { path: "/.htpasswd", regex: /^\w:.*$/, status: "potential" }
    ]

    asp_net_list = [
      { path: "/elmah.axd", severity: 3, regex: /Error log for/i, status: "confirmed" },
      { path: "/Trace.axd", regex: /Microsoft \.NET Framework Version/, :status => "confirmed" }
    ]

    coldfusion_list = [
      { path: "/CFIDE", severity: 4, regex: nil },
      { path: "CFIDE/administrator/enter.cfm", severity: 4, regex: nil }
    ] # TODO see metasploit for more ideas here


    jenkins_list = [
      { path: "/view/All/builds", regex: /Jenkins ver./i, status: "confirmed" },
      { path: "/view/All/newjob", regex: /Jenkins/i, status: "confirmed" },
      { path: "/asynchPeople/", regex: /Jenkins/i, status: "confirmed" },
      { path: "/userContent/", regex: /Jenkins/i, status: "confirmed" },
      { path: "/computer/", regex: /Jenkins/i, status: "confirmed" },
      { path: "/pview/", regex: /Jenkins/i, status: "confirmed" },
      { path: "/systeminf", regex: /Jenkins/i, status: "confirmed" },
      { path: "/systemInfo", regex: /Jenkins/i, status: "confirmed" },
      { path: "/script", regex: /Jenkins/i, status: "confirmed" },
      { path: "/signup", regex: /Jenkins/i, status: "confirmed" },
      { path: "/securityRealm/createAccount", regex: /Jenkins/i , status: "confirmed"}
    ]

    lotus_domino_list = [
      { path: "/$defaultview?Readviewentries", severity: 3, regex: /\<viewentries/, status: "confirmed" }
    ]

    php_list =[
      { path: "/phpinfo.php", severity: 4, regex: /<title>phpinfo\(\)/, status: "confirmed" }
    ]

    sap_netweaver_list =[ 
      { path: "/webdynpro/dispatcher/sap.com/caf~eu~gp~example~timeoff~wd/ACreate", 
        severity: 3, regex: nil, status: "potential" }, # https://www.exploit-db.com/exploits/44647
      { path: "/webdynpro/dispatcher/sap.com/caf~eu~gp~example~timeoff~wd/com.sap.caf.eu.gp.example.timeoff.wd.create.ACreate", 
        severity: 3, regex: nil, status: "potential" }, # https://www.exploit-db.com/exploits/44647
    ]

    sharepoint_list = [ 
      { path: "/_vti_bin/spsdisco.aspx", regex: /\<discovery/, status: "confirmed" },
      { path: "/_vti_pvt/service.cnf", regex: /vti_encoding/, status: "confirmed" },
      #{ path: "/_vti_inf.html", regex: nil },
      #{ path: "/_vti_bin/", regex: nil },
    ]

    splunk_list = [
      { path: "/en-US/splunkd/__raw/services/server/info/server-info?output_mode=json", 
        regex: /os_name_extended/, severity: 4, status: "confirmed" }, # CVE-2018-11409
    ]

    # https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Insecure%20Management%20Interface
    spring_boot_list =[
      { path: "/trace", severity: 4, regex: nil, status: "potential" },
      { path: "/env", severity: 4, regex: nil, status: "potential" },
      { path: "/heapdump", severity: 4, regex: nil, status: "potential" },
      { path: "/actuator/env", severity: 4, regex: nil, status: "potential" },
      { path: "/actuator/health", severity: 4, regex: nil, status: "potential" },
    ] # more: https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Insecure%20Management%20Interface/Intruder/springboot_actuator.txt

    tomcat_list = [ 
      { path: '/status', severity: 4, regex: /<p> Free memory:/ },
      { path: '/web-console', severity: 4, regex: nil },
      { path: '/jmx-console', severity: 4, regex: nil },
      { path: '/admin-console', severity: 4, regex: nil },
      { path: '/manager/html', severity: 4, regex: nil },
      { path: '/tomcat/manager/html', severity: 4, regex: nil },
      { path: '/host-manager/html', severity: 4, regex: nil },
      { path: '/server-manager/html', severity: 4, regex: nil },
      { path: '/web-console/Invoker', severity: 4, regex: nil },
      { path: '/jmx-console/HtmlAdaptor', severity: 4, regex: nil },
      { path: '/invoker/JMXInvokerServlet', severity: 4, regex: nil}
      # http://[host]:8090/invoker/EJBInvokerServlet
      # https://[host]:8453//invoker/EJBInvokerServlet
      #{ path: '/invoker/EJBInvokerServlet', severity: 4,  regex: nil} 
    ]

    vmware_horizon_list = [
      { path: "/portal/info.jsp", regex: /clientIPAddress/ } # CVE-2019-5513
    ]

    wordpress_list = [
      { path: '/wp-admin', severity: 5,  regex: nil, status: "potential" }, # TODO ... confirmed
      { path: '/xmlrpc.php', severity: 5, status: "confirmed", 
          regex: /XML-RPC server accepts POST requests only./ }
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
    apache_list.each { |x| work_q.push x } if is_product? "HTTP Server"  # Apache
    asp_net_list.each { |x| work_q.push x } if ( 
      is_product?("ASP.NET") || is_product?("ASP.NET MVC") )
    coldfusion_list.each { |x| work_q.push x } if is_product? "Coldfusion"  
    lotus_domino_list.each { |x| work_q.push x } if is_product? "Domino" 
    jenkins_list.each { |x| work_q.push x } if is_product? "Jenkins" 
    php_list.each { |x| work_q.push x } if is_product? "PHP" 
    sharepoint_list.each { |x| work_q.push x } if is_product? "Sharepoint"
    sap_netweaver_list.each { |x| work_q.push x } if is_product? "NetWeaver"
    splunk_list.each {|x| work_q.push x } if is_product? "Splunk"
    spring_boot_list.each { |x| work_q.push x } if is_product? "Spring Boot"
    tomcat_list.each { |x| work_q.push x } if is_product? "Tomcat" 
    vmware_horizon_list.each { |x| work_q.push x } if (
      is_product?("VMWare Horizon") || is_product?("VMWare Horizon View") ) 
    wordpress_list.each { |x| work_q.push x } if is_product? "Wordpress" 

    # then add our "always" stuff:
    generic_list.each { |x| work_q.push x } if opt_generic_content

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
              _create_entity("Uri", result[:uri]) if  opt_create_url
              
              _create_issue({
                name: "Discovered Content at #{result[:name]}",
                type: "discovered_content",
                severity: request_details[:severity] || 5,
                status: request_details[:status] || "potential",
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
