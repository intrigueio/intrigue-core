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
      #{ path: "/api", body_regex: nil },
      { path: "/.git", severity: 2, body_regex: /<h1>Index of/, status: "confirmed" },
      { path: "/.hg", severity: 2, body_regex: /<h1>Index of/, status: "confirmed"  },
      { path: "/.svn", severity: 2, body_regex: /<h1>Index of/, status: "confirmed" },
      { path: "/.bzr", severity: 2, body_regex: /<h1>Index of/, status: "confirmed" },
      # https://github.com/laravel/laravel/blob/master/.env.example
      { path: "/.env", severity: 1, body_regex: /APP_ENV/, status: "confirmed" },  
      #{ path: "/.csv", body_regex: /<h1>Index of/ },
      #{ path: "/.bak", body_regex: /<h1>Index of/ },
      #{ path: "/crossdomain.xml", body_regex: /\<cross-domain-policy/, severity: 6, status: "confirmed"}, #tighten regex?
      #{ path: "/clientaccesspolicy.xml", body_regex: /\<access-policy/, severity: 6, status: "confirmed"}, #tighten regex?
      #{ path: "/portal", body_regex: nil },
      #{ path: "/admin", body_regex: nil },
      #{ path: "/test", body_regex: nil },
    ]

    # technology specifics 
    apache_list = [
      { path: "/.htaccess", body_regex: /AuthName/, severity: 3, status: "confirmed" },
      { path: "/.htaccess.bak", body_regex: /AuthName/, severity: 3, status: "confirmed" },
      #{ path: "/.htpasswd", body_regex: /(:\$|:\{.*\n|[a-z]:.*$)/, severity: 1, status: "confirmed" },
      { path: "/server-status", body_regex: /Server Version/i, severity: 3, status: "confirmed" },
      { path: "/server-info", body_regex: /Apache Server Information/i, severity: 4, status: "confirmed" }
    ]

    asp_net_list = [
      { path: "/elmah.axd", severity: 1, body_regex: /Error log for/i, status: "confirmed" },
      { path: "/errorlog.axd", severity: 1, body_regex: /Error log for/i, status: "confirmed" },
      { path: "/Trace.axd", severity: 5, body_regex: /Microsoft \.NET Framework Version/, :status => "confirmed" }
      # /páginas/default.aspx
      # /pages/default.aspx 
    ]

    # TODO - see: https://foundeo.com/hack-my-cf/coldfusion-security-issues.cfm
    # TODO - see: metasploit
    coldfusion_list = [
      { path: "/CFIDE", severity: 5, body_regex: nil, :status => "potential"  },
      
      { path: "/CFIDE/scripts", severity: 4, body_regex: nil, :status => "potential"  },
      # 
      { path: "/CFIDE/debug/", severity: 1, body_regex: nil, :status => "potential"  },
      { path: "/CFIDE/administrator/enter.cfm", severity: 5, body_regex: nil, :status => "potential"  },
      { path: "/CFIDE/administrator/aboutcf.cfm", severity: 5, body_regex: nil, :status => "potential"  },
      { path: "/CFIDE/administrator/welcome.cfm", severity: 5, body_regex: nil, :status => "potential"  },
      { path: "/CFIDE/administrator/index.cfm", severity: 5, body_regex: nil, :status => "potential"  },
      # Jakarta Virtual Directory Exposed 
      { path: "/jakarta/isapi_redirect.log", severity: 4, body_regex: nil, :status => "potential"  },
      { path: "/jakarta/isapi_redirect.properties", severity: 4, body_regex: nil, :status => "potential"  },
      # Bitcoin Miner Discovered 
      { path: "/CFIDE/m", severity: 1, body_regex: nil, :status => "potential"  },
      { path: "/CFIDE/m32", severity: 1, body_regex: nil, :status => "potential"  },
      { path: "/CFIDE/m64", severity: 1, body_regex: nil, :status => "potential"  },
      { path: "/CFIDE/updates.cfm", severity: 1, body_regex: nil, :status => "potential" },
      # XSS Injection in cfform.js 
      { path: "/CFIDE/scripts/cfform.js", severity: 3, body_regex: /document\.write/, :status => "confirmed"  },
      # OpenBD AdminAPI Exposed to the Public 
      { path: "/bluedragon/adminapi/", severity: 1, body_regex: nil, :status => "potential"  },
      # ColdFusion Example Applications Installed -
      { path: "/cfdocs/exampleapps/", severity: 4, body_regex: nil, :status => "potential"  },
      { path: "/CFIDE/gettingstarted/", severity: 4, body_regex: nil, :status => "potential"  },
      # Svn / git Hidden Directory Exposed 
      { path: "/.svn/text-base/index.cfm.svn-base", severity: 4, body_regex: nil, :status => "potential"  },
      { path: "/.git/config", severity: 4, body_regex: nil, :status => "potential"  },
      # Lucee Server Context is Public
      { path: "/lucee-server/", severity: 3, body_regex: nil, :status => "potential"  },
      # Lucee Docs are Public -
      { path: "/lucee/doc.cfm", severity: 4, body_regex: nil, :status => "potential"  },
      { path: "/lucee/doc/index.cfm", severity: 3, body_regex: nil, :status => "potential"  },
      # Lucee Server Context is Public
      { path: "/railo-server-context/", severity: 3, body_regex: nil, :status => "potential"  },
      # The /cf_scripts/scripts directory is in default location
      { path: "/cf_scripts/scripts/", severity: 3, body_regex: nil, :status => "potential"  },
      { path: "/cfscripts_2018/", severity: 3, body_regex: nil, :status => "potential"  },
      # Backdoor Discovered
      { path: "/CFIDE/h.cfm", severity: 1, body_regex: nil, :status => "potential"  },
      # Exposed _mmServerScripts
      { path: "/_mmServerScripts", severity: 1, body_regex: nil, :status => "potential"  }
    ]

    globalprotect_list = [ # https://blog.orange.tw/2019/07/attacking-ssl-vpn-part-1-preauth-rce-on-palo-alto.html
      { path: "/global-protect/portal/css/login.css", severity: 1,
          header_regex: /^Last-Modified:.*(Jan 2018|Feb 2018|Mar 2018|Apr 2018|May 2018|Jun 2018|2017).*$/i, status: "confirmed" } 
    ]

    jenkins_list = [
      { path: "/view/All/builds", severity: 4, body_regex: /Jenkins ver./i, status: "confirmed" },
      { path: "/view/All/newjob",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { path: "/asynchPeople/",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { path: "/userContent/",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { path: "/computer/",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { path: "/pview/",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { path: "/systemInfo",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { path: "/script",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { path: "/signup",  severity: 5, body_regex: /Jenkins/i, status: "confirmed" },
      { path: "/securityRealm/createAccount", severity: 4, body_regex: /Jenkins/i , status: "confirmed"}
    ]

    jforum_list = [ # CVE-2019-7550
      { path: "/register/check/username?username=thisaccountdoesntexist", severity: 4,
          body_regex: /^true$/i, status: "confirmed" } # CVE-2019-7550
    ] 

    jira_list = [ # https://x.x.x.x?filterView=popular
      { path: "/secure/ManageFilters.jspa", severity: 3,
          body_regex: /<title>Manage Filters/i, status: "confirmed" } 
    ]
    # 
    joomla_list = [   # https://packetstormsecurity.com/files/151619/Joomla-Agora-4.10-Bypass-SQL-Injection.html
        { path: "/index.php?option=com_agora&task='", severity: 2, status: "potential" } 
    ] 

    lotus_domino_list = [
      { path: "/$defaultview?Readviewentries", severity: 3, body_regex: /\<viewentries/, status: "confirmed" }
    ]

    php_list =[
      { path: "/phpinfo.php", severity: 4, body_regex: /<title>phpinfo\(\)/, status: "confirmed" }
    ]

    php_my_admin_list = [
      { path: "/phpMyAdmin/scripts/setup.php", severity: 4, body_regex: nil, status: "potential" }
    ]

    # https://know.bishopfox.com/blog/breaching-the-trusted-perimeter
    pulse_secure_list = [
      { path: "/dana-na/nc/nc_gina_ver.txt", severity: 3, body_regex: /classid/, status: "confirmed" }, # CVE-2019-11510
      { path: "/dana-na/../dana/html5acc/guacamole/../../../../../../etc/passwd?/dana/html5acc/guacamole/", severity: 1, body_regex: nil, status: "confirmed" },
      #{ path: "/dana-na/../dana/html5acc/guacamole/../../../../../../data/runtime/mtmp/system?/dana/html5acc/guacamole/", severity: 1, body_regex: nil, status: "potential" },
      #{ path: "/dana-na/../dana/html5acc/guacamole/../../../../../../data/runtime/mtmp/lmdb/dataa/data.mdb?/dana/html5acc/guacamole/", severity: 1, body_regex: nil, status: "potential" },
      #{ path: "/dana-na/../dana/html5acc/guacamole/../../../../../../data/runtime/mtmp/lmdb/randomVal/data.mdb?/dana/html5acc/guacamole/", severity: 1, body_regex: nil, status: "potential" }
    ]

    sap_netweaver_list =[ 
      { path: "/webdynpro/dispatcher/sap.com/caf~eu~gp~example~timeoff~wd/ACreate", 
        severity: 3, body_regex: /data-sap-ls-system-platform/, status: "confirmed" }, # https://www.exploit-db.com/exploits/44647
      { path: "/webdynpro/dispatcher/sap.com/caf~eu~gp~example~timeoff~wd/com.sap.caf.eu.gp.example.timeoff.wd.create.ACreate", 
        severity: 3, body_regex: /data-sap-ls-system-platform/, status: "confirmed" }, # https://www.exploit-db.com/exploits/44647
    ]

    sharepoint_list = [ 
      { path: "/_vti_bin/spsdisco.aspx", body_regex: /\<discovery/, status: "confirmed" },
      { path: "/_vti_bin/sites.asmx?wsdl", severity: 4, status: "potential" },
      { path: "/_vti_pvt/service.cnf", body_regex: /vti_encoding/, status: "confirmed" },
      #{ path: "/_vti_inf.html", body_regex: nil },
      #{ path: "/_vti_bin/", body_regex: nil },
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

    # https://www.exploit-db.com/exploits/43009 - c
    #"/solr/gettingstarted/select?q=test"


    splunk_list = [
      { path: "/en-US/splunkd/__raw/services/server/info/server-info?output_mode=json", 
        body_regex: /os_name_extended/, severity: 4, status: "confirmed" }, # CVE-2018-11409
    ]

    # https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Insecure%20Management%20Interface
    spring_boot_list =[
      { path: "/trace", severity: 4, body_regex: nil, status: "potential" },
      { path: "/env", severity: 4, body_regex: nil, status: "potential" },
      { path: "/heapdump", severity: 4, body_regex: nil, status: "potential" },
      { path: "/actuator/env", severity: 4, body_regex: nil, status: "potential" },
      { path: "/actuator/health", severity: 4, body_regex: nil, status: "potential" },
    ] # more: https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Insecure%20Management%20Interface/Intruder/springboot_actuator.txt

    tomcat_list = [ 
      { path: '/status', severity: 4, body_regex: /<p> Free memory:/ },
      { path: '/web-console', severity: 4, body_regex: nil },
      { path: '/jmx-console', severity: 4, body_regex: nil },
      { path: '/admin-console', severity: 4, body_regex: nil },
      { path: '/manager/html', severity: 4, body_regex: nil },
      { path: '/tomcat/manager/html', severity: 4, body_regex: nil },
      { path: '/host-manager/html', severity: 4, body_regex: nil },
      { path: '/server-manager/html', severity: 4, body_regex: nil },
      { path: '/web-console/Invoker', severity: 4, body_regex: nil },
      { path: '/jmx-console/HtmlAdaptor', severity: 4, body_regex: nil },
      { path: '/invoker/JMXInvokerServlet', severity: 4, body_regex: nil}
      # http://[host]:8090/invoker/EJBInvokerServlet
      # https://[host]:8453//invoker/EJBInvokerServlet
      #{ path: '/invoker/EJBInvokerServlet', severity: 4,  body_regex: nil} 
    ]

    # VMware Horizon
    vmware_horizon_list = [
      { path: "/portal/info.jsp", severity: 4, body_regex: /clientIPAddress/, status: "confirmed" } # CVE-2019-5513
    ]

    # Oracle Weblogic Server
    #  - CVE-2017-10271
    #  - April 2019 0day: http://bit.ly/2ZxYIjS
    weblogic_list = [
      { path: "/wls-wsat/CoordinatorPortType", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" },
      { path: "/wls-wsat/RegistrationPortTypeRPC", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" },
      { path: "/wls-wsat/ParticipantPortType", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" }, 
      { path: "/wls-wsat/RegistrationRequesterPortType", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" },
      { path: "/wls-wsat/CoordinatorPortType11", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" },
      { path: "/wls-wsat/RegistrationPortTypeRPC11", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" }, 
      { path: "/wls-wsat/ParticipantPortType11", severity: 3, body_regex: /<td>WSDL:/,status: "confirmed" }, 
      { path: "/wls-wsat/RegistrationRequesterPortType11", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" }
    ]

    websphere_list = [
      { path: "/AddressBookJ2WB", severity: 5, status: "potential" },
      { path: "/AddressBookJ2WE/services/AddressBook", severity: 5, status: "potential" },
      { path: "/AlbumCatalogWeb", severity: 5, status: "potential" },
      { path: "/AppManagementStatus", severity: 5, status: "potential" }
    ] # see more at https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/websphere.txt

    wordpress_list = [
      { path: '/wp-config.php~', severity: 1,  body_regex: /DB_PASSWORD/, status: "confirmed" },
      { path: '/wp-json/wp/v2/users', severity: 4,  body_regex: /slug/, status: "confirmed" }, 
      { path: '/wp-admin', severity: 5,  body_regex: /Powered by WordPress/, status: "confirmed" },
      { path: '/xmlrpc.php', severity: 5, status: "confirmed", body_regex: /XML-RPC server accepts POST requests only./ }
      #{ path: '/wp-login.php?action=register', severity: 4, status: "potential"} # "User registration is currently not allowed."

      # TODO - look for "1.3.9.1" to disprove vulnerability 
      #{ path: '/wp-content/plugins/easy-wp-smtp/readme.txt', severity: 1,  body_regex: /Easy WP SMTP/i, status: "potential" },  
      #{ path: '/wp-content/plugins/easy-wp-smtp/css/style.css', severity: 2,  body_regex: /swpsmtp_settings_form/i, status: "potential" },  
      #{ path: '/wp-content/plugins/easy-wp-smtp/', severity: 2,  body_regex: /debug_log/i, status: "potential" },
      #{ path: '/wp-content/plugins/easy-wp-smtp/inc/', severity: 2,  body_regex: /debug_log/i, status: "potential" }
    ] 
    
    # add wordpress plugins list from a file
    #File.open("#{$intrigue_basedir}/data/wordpress_plugins.list").each_line do |l|
    #  next if l =~ /^#/
    #  #_log "Adding Wordpress plugin check: #{l.strip}"
    #  wordpress_list << { path: "#{l.strip}/" , severity: 5,  body_regex: nil, status: "potential" }
    #  wordpress_list << { path: "#{l.strip}/readme.txt" , severity: 5,  body_regex: /Contributors:/i, status: "confirmed" }
    #end

    # Create our queue of work from the checks in brute_list
    work_q = Queue.new
    
    #  first handle our specific here (more likely to be interesting)
    apache_list.each { |x| work_q.push x } if is_product? "HTTP Server"  # Apache
    asp_net_list.each { |x| work_q.push x } if ( 
      is_product?("ASP.NET") || is_product?("ASP.NET MVC") )
    coldfusion_list.each { |x| work_q.push x } if is_product? "Coldfusion"  
    globalprotect_list.each { |x| work_q.push x } if is_product? "GlobalProtect" 
    jenkins_list.each { |x| work_q.push x } if is_product? "Jenkins" 
    jforum_list.each { |x| work_q.push x } if is_product? "Jforum"
    jira_list.each { |x| work_q.push x } if is_product? "Jira"
    joomla_list.each { |x| work_q.push x } if is_product? "Joomla!" 
    lotus_domino_list.each { |x| work_q.push x } if is_product? "Domino" 
    php_list.each { |x| work_q.push x } if is_product? "PHP" 
    php_my_admin_list.each { |x| work_q.push x } if is_product? "phpMyAdmin" 
    pulse_secure_list.each { |x| work_q.push x } if is_product? "Junos Pulse Secure Access Service" 
    sharepoint_list.each { |x| work_q.push x } if is_product? "Sharepoint"
    sap_netweaver_list.each { |x| work_q.push x } if is_product? "NetWeaver"
    splunk_list.each {|x| work_q.push x } if is_product? "Splunk"
    spring_boot_list.each { |x| work_q.push x } if is_product? "Spring Boot"
    tomcat_list.each { |x| work_q.push x } if is_product? "Tomcat" 
    vmware_horizon_list.each { |x| work_q.push x } if is_product?("Horizon View")
    weblogic_list.each { |x| work_q.push x } if is_product? "Weblogic Server" 
    websphere_list.each { |x| work_q.push x } if is_product? "WebSphere" 
    wordpress_list.each { |x| work_q.push x } if is_product? "Wordpress" 

    # then add our "always" stuff:
    generic_list.each { |x| work_q.push x } if opt_generic_content

    ###
    ### Do the work 
    ###
    results = make_http_requests_from_queue(uri, work_q, opt_threads, opt_create_url, true) # always create an issue

    _log "Got matches: #{results}"

  end # end run method

end
end
end



