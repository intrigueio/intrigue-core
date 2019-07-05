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
        {:name => "override_fingerprint", regex: "alpha_numeric", :default => "" },
        {:name => "check_generic_content", regex: "boolean", :default => true }
      ],
      :created_types => ["Uri"]
    }
  end

  def is_product?(product_name)

    # first, if an override fingerprint was specified, just use that
    override = _get_option("override_fingerprint")
    if override.length > 0
      return (override == product_name) ? true : false
    end

    # okay no override, check the enity's fingerprint
    return false unless _get_entity_detail("fingerprint")
    
    out = _get_entity_detail("fingerprint").any?{|v| v['product'] =~ /#{product_name}/ if v['product']}
    _log_good "Matched URI to Product: #{product_name} !" if out
  out
  end

  def sleep_until_enriched
    entity_enriched = @entity.enriched?
    cycles = 30 
    until entity_enriched || cycles == 0
      _log "Waiting 10s for entity to be enriched... (#{cycles-=1} / #{cycles})"
        sleep 10
      entity_enriched = Intrigue::Model::Entity.first(:id => @entity.id).enriched?
    end
  end

  def run
    super

    sleep_until_enriched unless _get_option("override_fingerprint").length > 0

    uri = _get_entity_name
    opt_threads = _get_option("threads") 
    opt_create_url = _get_option("create_url")
    opt_generic_content = _get_option("check_generic_content") 

    generic_list = [ 
      #{ path: "/api", regex: nil },
      { path: "/.git", severity: 3, regex: /<h1>Index of/ },
      { path: "/.hg", severity: 3, regex: /<h1>Index of/ },
      { path: "/.svn", severity: 3, regex: /<h1>Index of/ },
      { path: "/.bzr", severity: 3, regex: /<h1>Index of/ },
      #{ path: "/.csv", regex: /<h1>Index of/ },
      #{ path: "/.bak", regex: /<h1>Index of/ },
      #{ path: "/crossdomain.xml", regex: /\<cross-domain-policy/, severity: 6, status: "confirmed"}, #tighten regex?
      #{ path: "/clientaccesspolicy.xml", regex: /\<access-policy/, severity: 6, status: "confirmed"}, #tighten regex?
      #{ path: "/portal", regex: nil },
      #{ path: "/admin", regex: nil },
      #{ path: "/test", regex: nil },
    ]

    # technology specifics 
    apache_list = [
      { path: "/.htaccess", regex: /AuthName/, severity: 3, status: "confirmed" },
      { path: "/.htaccess.bak", regex: /AuthName/, severity: 3, status: "confirmed" },
      #{ path: "/.htpasswd", regex: /^\w:.*$/, severity: 1, status: "potential" },
      { path: "/server-status", regex: /Server Version/i, severity: 4, status: "confirmed" }
    ]

    asp_net_list = [
      { path: "/elmah.axd", severity: 2, regex: /Error log for/i, status: "confirmed" },
      { path: "/Trace.axd", severity: 5, regex: /Microsoft \.NET Framework Version/, :status => "confirmed" }
    ]

    coldfusion_list = [
      { path: "/CFIDE", severity: 5, regex: nil, :status => "potential"  },
      { path: "/CFIDE/administrator/enter.cfm", severity: 5, regex: nil, :status => "potential"  },
      { path: "/CFIDE/administrator/aboutcf.cfm", severity: 5, regex: nil, :status => "potential"  },
      { path: "/CFIDE/administrator/welcome.cfm", severity: 5, regex: nil, :status => "potential"  },
      { path: "/CFIDE/administrator/index.cfm", severity: 5, regex: nil, :status => "potential"  }
    ] # TODO see metasploit for more ideas here


    jenkins_list = [
      { path: "/view/All/builds", severity: 4, regex: /Jenkins ver./i, status: "confirmed" },
      { path: "/view/All/newjob",  severity: 4, regex: /Jenkins/i, status: "confirmed" },
      { path: "/asynchPeople/",  severity: 4, regex: /Jenkins/i, status: "confirmed" },
      { path: "/userContent/",  severity: 4, regex: /Jenkins/i, status: "confirmed" },
      { path: "/computer/",  severity: 4, regex: /Jenkins/i, status: "confirmed" },
      { path: "/pview/",  severity: 4, regex: /Jenkins/i, status: "confirmed" },
      { path: "/systemInfo",  severity: 4, regex: /Jenkins/i, status: "confirmed" },
      { path: "/script",  severity: 4, regex: /Jenkins/i, status: "confirmed" },
      { path: "/signup",  severity: 5, regex: /Jenkins/i, status: "confirmed" },
      { path: "/securityRealm/createAccount", severity: 4, regex: /Jenkins/i , status: "confirmed"}
    ]

    jforum_list = [ # CVE-2019-7550
      { path: "/register/check/username?username=thisaccountdoesntexist", severity: 4,
          regex: /^true$/i, status: "confirmed" } # CVE-2019-7550
    ] 

    # 
    joomla_list = [
        # https://packetstormsecurity.com/files/151619/Joomla-Agora-4.10-Bypass-SQL-Injection.html
        { path: "/index.php?option=com_agora&task='", severity: 2, status: "potential" } 
    ] 


    lotus_domino_list = [
      { path: "/$defaultview?Readviewentries", severity: 3, regex: /\<viewentries/, status: "confirmed" }
    ]

    php_list =[
      { path: "/phpinfo.php", severity: 4, regex: /<title>phpinfo\(\)/, status: "confirmed" }
    ]

    php_my_admin_list = [
      { path: "/phpMyAdmin/scripts/setup.php", severity: 4, regex: nil, status: "potential" }
    ]

    sap_netweaver_list =[ 
      { path: "/webdynpro/dispatcher/sap.com/caf~eu~gp~example~timeoff~wd/ACreate", 
        severity: 3, regex: /data-sap-ls-system-platform/, status: "confirmed" }, # https://www.exploit-db.com/exploits/44647
      { path: "/webdynpro/dispatcher/sap.com/caf~eu~gp~example~timeoff~wd/com.sap.caf.eu.gp.example.timeoff.wd.create.ACreate", 
        severity: 3, regex: /data-sap-ls-system-platform/, status: "confirmed" }, # https://www.exploit-db.com/exploits/44647
    ]

    sharepoint_list = [ 
      { path: "/_vti_bin/spsdisco.aspx", regex: /\<discovery/, status: "confirmed" },
      { path: "/_vti_pvt/service.cnf", regex: /vti_encoding/, status: "confirmed" },
      #{ path: "/_vti_inf.html", regex: nil },
      #{ path: "/_vti_bin/", regex: nil },
      #_vti_bin/shtml.exe/junk_nonexistant.exe
      #_vti_txt/_vti_cnf/
      #_vti_txt/
      #_vti_pvt/deptodoc.btr
      #_vti_pvt/doctodep.btr
      #_vti_pvt/services.org
      #_vti_bin/shtml.dll/_vti_rpc?method=server+version%3a4%2e0%2e2%2e2611
      #_vti_bin/shtml.exe/_vti_rpc?method=server+version%3a4%2e0%2e2%2e2611
      #_vti_bin/_vti_aut/author.dll?method=list+documents%3a3%2e0%2e2%2e1706&service%5fname=&listHiddenDocs=true&listExplorerDocs=true&listRecurse=false&listFiles=true&listFolders=true&listLinkInfo=true&listInclude
      #_vti_bin/_vti_aut/author.exe?method=list+documents%3a3%2e0%2e2%2e1706&service%5fname=&listHiddenDocs=true&listExplorerDocs=true&listRecurse=false&listFiles=true&listFolders=true&listLinkInfo=true&listInclude
      #_vti_bin/_vti_aut/dvwssr.dll
      #_vti_bin/_vti_aut/fp30reg.dll?xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
      #_vti_bin/_vti_aut/fp30reg.dll
      #_vti_pvt/access.cnf
      #_vti_pvt/botinfs.cnf
      #_vti_pvt/bots.cnf
      #_vti_pvt/service.cnf
      #_vti_pvt/services.cnf
      #_vti_pvt/svacl.cnf
      #_vti_pvt/writeto.cnf
      #_vti_pvt/linkinfo.cnf
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

    # VMware Horizon
    vmware_horizon_list = [
      { path: "/portal/info.jsp", severity: 4, regex: /clientIPAddress/, status: "confirmed" } # CVE-2019-5513
    ]

    # Oracle Weblogic Server
    #  - CVE-2017-10271
    #  - April 2019 0day: http://bit.ly/2ZxYIjS
    weblogic_list = [
      { path: "/wls-wsat/CoordinatorPortType", severity: 3, regex: /<td>WSDL:/, status: "potential" },
      { path: "/wls-wsat/RegistrationPortTypeRPC", severity: 3, regex: /<td>WSDL:/, status: "potential" },
      { path: "/wls-wsat/ParticipantPortType", severity: 3, regex: /<td>WSDL:/, status: "potential" }, 
      { path: "/wls-wsat/RegistrationRequesterPortType", severity: 3, regex: /<td>WSDL:/, status: "potential" },
      { path: "/wls-wsat/CoordinatorPortType11", severity: 3, regex: /<td>WSDL:/, status: "potential" },
      { path: "/wls-wsat/RegistrationPortTypeRPC11", severity: 3, regex: /<td>WSDL:/, status: "potential" }, 
      { path: "/wls-wsat/ParticipantPortType11", severity: 3, regex: /<td>WSDL:/,status: "potential" }, 
      { path: "/wls-wsat/RegistrationRequesterPortType11", severity: 3, regex: /<td>WSDL:/, status: "potential" }
    ]

    websphere_list = [
      { path: "/AddressBookJ2WB", severity: 5, status: "potential" },
      { path: "/AddressBookJ2WE/services/AddressBook", severity: 5, status: "potential" },
      { path: "/AlbumCatalogWeb", severity: 5, status: "potential" },
      { path: "/AppManagementStatus", severity: 5, status: "potential" }
    ] # see more at https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/websphere.txt

    wordpress_list = [
      { path: '/wp-json/wp/v2/users', severity: 4,  regex: /slug/, status: "confirmed" }, 
      { path: '/wp-admin', severity: 5,  regex: /Powered by WordPress/, status: "confirmed" },
      { path: '/xmlrpc.php', severity: 5, status: "confirmed", regex: /XML-RPC server accepts POST requests only./ },
      # TODO - look for "1.3.9.1" to disprove vulnerability 
      #{ path: '/wp-content/plugins/easy-wp-smtp/readme.txt', severity: 1,  regex: /Easy WP SMTP/i, status: "potential" },  
      #{ path: '/wp-content/plugins/easy-wp-smtp/css/style.css', severity: 2,  regex: /swpsmtp_settings_form/i, status: "potential" },  
      #{ path: '/wp-content/plugins/easy-wp-smtp/', severity: 2,  regex: /debug_log/i, status: "potential" },
      #{ path: '/wp-content/plugins/easy-wp-smtp/inc/', severity: 2,  regex: /debug_log/i, status: "potential" }
    ] 
    
    # add wordpress plugins list from a file
    #File.open("#{$intrigue_basedir}/data/wordpress_plugins.list").each_line do |l|
    #  next if l =~ /^#/
    #  #_log "Adding Wordpress plugin check: #{l.strip}"
    #  wordpress_list << { path: "#{l.strip}/" , severity: 5,  regex: nil, status: "potential" }
    #  wordpress_list << { path: "#{l.strip}/readme.txt" , severity: 5,  regex: /Contributors:/i, status: "confirmed" }
    #end

    # Create our queue of work from the checks in brute_list
    work_q = Queue.new
    
    #  first handle our specific here (more likely to be interesting)
    apache_list.each { |x| work_q.push x } if is_product? "HTTP Server"  # Apache
    asp_net_list.each { |x| work_q.push x } if ( 
      is_product?("ASP.NET") || is_product?("ASP.NET MVC") )
    coldfusion_list.each { |x| work_q.push x } if is_product? "Coldfusion"  
    lotus_domino_list.each { |x| work_q.push x } if is_product? "Domino" 
    jenkins_list.each { |x| work_q.push x } if is_product? "Jenkins" 
    jforum_list.each { |x| work_q.push x } if is_product? "Jforum" 
    joomla_list.each { |x| work_q.push x } if is_product? "Joomla!" 
    php_list.each { |x| work_q.push x } if is_product? "PHP" 
    sharepoint_list.each { |x| work_q.push x } if is_product? "Sharepoint"
    sap_netweaver_list.each { |x| work_q.push x } if is_product? "NetWeaver"
    splunk_list.each {|x| work_q.push x } if is_product? "Splunk"
    spring_boot_list.each { |x| work_q.push x } if is_product? "Spring Boot"
    tomcat_list.each { |x| work_q.push x } if is_product? "Tomcat" 
    vmware_horizon_list.each { |x| work_q.push x } if (
      is_product?("VMWare Horizon") || is_product?("VMWare Horizon View") ) 
    weblogic_list.each { |x| work_q.push x } if is_product? "Weblogic Server" 
    websphere_list.each { |x| work_q.push x } if is_product? "WebSphere" 
    wordpress_list.each { |x| work_q.push x } if is_product? "Wordpress" 

    # then add our "always" stuff:
    generic_list.each { |x| work_q.push x } if opt_generic_content

    ###
    ### Do the work 
    ###
    make_http_requests_from_queue(uri, work_q, opt_threads, opt_create_url, true) # always create an issue

  end # end run method

end
end
end



