module Intrigue
module Task
class UriBruteFocusedContent < BaseTask

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

  def run
    super

    uri = _get_entity_name
    opt_threads = _get_option("threads") 
    opt_create_url = _get_option("create_url")
    opt_generic_content = _get_option("check_generic_content") 

    # first, if an override fingerprint was specified, just use that
    override = _get_option("override_fingerprint")

    # we need a FP here, so hold off until 
    sleep_until_enriched unless override.length > 0

    fingerprint = _get_entity_detail("fingerprint")

    generic_list = [ 
      #{ path: "/api", body_regex: nil },
      { issue_type: "leaked_repository", path: "/.git", severity: 2, body_regex: /<h1>Index of/, status: "confirmed" },
      { issue_type: "leaked_repository", path: "/.git/config", severity: 2, body_regex: /repositoryformatversion/, :status => "confirmed"  },
      { issue_type: "leaked_repository", path: "/.hg", severity: 2, body_regex: /<h1>Index of/, status: "confirmed"  },
      { issue_type: "leaked_repository", path: "/.svn", severity: 2, body_regex: /<h1>Index of/, status: "confirmed" },
      { issue_type: "leaked_repository", path: "/.bzr", severity: 2, body_regex: /<h1>Index of/, status: "confirmed" },
      
      # TODO ... move this to laravel-only. 
      # https://github.com/laravel/laravel/blob/master/.env.example
      { issue_type: "laravel_env_file", path: "/.env", severity: 1, body_regex: /DB_CONNECTION/, status: "confirmed" },
      
      { issue_type: "htaccess", path: "/.htaccess", body_regex: /AuthName/, severity: 3, status: "confirmed" },
      { issue_type: "htaccess", path: "/.htaccess.bak", body_regex: /AuthName/, severity: 3, status: "confirmed" },
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
     #{ issue_type: "htpasswd", path: "/.htpasswd", body_regex: /(:\$|:\{.*\n|[a-z]:.*$)/, severity: 1, status: "confirmed" },
      { issue_type: "apache_server_status", path: "/server-status", body_regex: /Server Version/i, severity: 3, status: "confirmed" },
      { issue_type: "apache_server_info", path: "/server-info", body_regex: /Apache Server Information/i, severity: 4, status: "confirmed" }
    ]

    asp_net_list = [
      { issue_type: "aspnet_elmah_axd", path: "/elmah.axd", severity: 1, body_regex: /Error log for/i, status: "confirmed" },
      { issue_type: "aspnet_elmah_axd", path: "/errorlog.axd", severity: 1, body_regex: /Error log for/i, status: "confirmed" },
      { issue_type: "aspnet_trace_axd", path: "/Trace.axd", severity: 5, body_regex: /Microsoft \.NET Framework Version/, :status => "confirmed" }
      # /páginas/default.aspx
      # /pages/default.aspx 
    ]

    # TODO - see: https://foundeo.com/hack-my-cf/coldfusion-security-issues.cfm
    # TODO - see: metasploit
    coldfusion_list = [
      #{ issue_type: "coldfusion_config", path: "/CFIDE", severity: 5, body_regex: nil, :status => "potential"  },
      #{ issue_type: "coldfusion_config", path: "/CFIDE/scripts", severity: 4, body_regex: nil, :status => "potential"  },
      #{ issue_type: "coldfusion_config", path: "/CFIDE/debug/", severity: 1, body_regex: nil, :status => "potential"  },
      #{ issue_type: "coldfusion_config", path: "/CFIDE/administrator/enter.cfm", severity: 5, body_regex: nil, :status => "potential"  },
      #{ issue_type: "coldfusion_config", path: "/CFIDE/administrator/aboutcf.cfm", severity: 5, body_regex: nil, :status => "potential"  },
      #{ issue_type: "coldfusion_config", path: "/CFIDE/administrator/welcome.cfm", severity: 5, body_regex: nil, :status => "potential"  },
      #{ issue_type: "coldfusion_config", path: "/CFIDE/administrator/index.cfm", severity: 5, body_regex: nil, :status => "potential"  },
      # Jakarta Virtual Directory Exposed 
      #{ issue_type: "coldfusion_config", path: "/jakarta/isapi_redirect.log", severity: 4, body_regex: nil, :status => "potential"  },
      #{ issue_type: "coldfusion_config", path: "/jakarta/isapi_redirect.properties", severity: 4, body_regex: nil, :status => "potential"  },
      # Bitcoin Miner Discovered 
      { issue_type: "coldfusion_cryptominer", path: "/CFIDE/m", severity: 1, body_regex: nil, :status => "potential"  },
      { issue_type: "coldfusion_cryptominer", path: "/CFIDE/m32", severity: 1, body_regex: nil, :status => "potential"  },
      { issue_type: "coldfusion_cryptominer", path: "/CFIDE/m64", severity: 1, body_regex: nil, :status => "potential"  },
      #{ issue_type: "coldfusion_config", path: "/CFIDE/updates.cfm", severity: 1, body_regex: nil, :status => "potential" },
      # XSS Injection in cfform.js 
      #{ issue_type: "coldfusion_config", path: "/CFIDE/scripts/cfform.js", severity: 3, body_regex: /document\.write/, :status => "confirmed"  },
      # OpenBD AdminAPI Exposed to the Public 
      #{ issue_type: "coldfusion_config", path: "/bluedragon/adminapi/", severity: 1, body_regex: nil, :status => "potential"  },
      # ColdFusion Example Applications Installed -
      #{ issue_type: "coldfusion_config", path: "/cfdocs/exampleapps/", severity: 4, body_regex: nil, :status => "potential"  },
      #{ issue_type: "coldfusion_config", path: "/CFIDE/gettingstarted/", severity: 4, body_regex: nil, :status => "potential"  },
      # Svn / git Hidden Directory Exposed 
      #{ issue_type: "coldfusion_config",  path: "/.svn/text-base/index.cfm.svn-base", severity: 4, body_regex: nil, :status => "potential"  },
      # Lucee Server Context is Public
      #{ issue_type: "coldfusion_config", path: "/lucee-server/", severity: 3, body_regex: nil, :status => "potential"  },
      # Lucee Docs are Public -
      #{ issue_type: "coldfusion_config", path: "/lucee/doc.cfm", severity: 4, body_regex: nil, :status => "potential"  },
      #{ issue_type: "coldfusion_config", path: "/lucee/doc/index.cfm", severity: 3, body_regex: nil, :status => "potential"  },
      # Lucee Server Context is Public
      #{ issue_type: "coldfusion_config", path: "/railo-server-context/", severity: 3, body_regex: nil, :status => "potential"  },
      # The /cf_scripts/scripts directory is in default location
      #{ issue_type: "coldfusion_config", path: "/cf_scripts/scripts/", severity: 3, body_regex: nil, :status => "potential"  },
      #{ issue_type: "coldfusion_config", path: "/cfscripts_2018/", severity: 3, body_regex: nil, :status => "potential"  },
      # Backdoor Discovered
      #{ issue_type: "coldfusion_config", path: "/CFIDE/h.cfm", severity: 1, body_regex: nil, :status => "potential"  },
      # Exposed _mmServerScripts
      #{ issue_type: "coldfusion_config", path: "/_mmServerScripts", severity: 1, body_regex: nil, :status => "potential"  }
    ]

    globalprotect_list = [ # https://blog.orange.tw/2019/07/attacking-ssl-vpn-part-1-preauth-rce-on-palo-alto.html
      { issue_type: "vulnerable_globalprotect_cve_2019_1579", path: "/global-protect/portal/css/login.css", severity: 1,
          header_regex: /^Last-Modified:.*(Jan 2018|Feb 2018|Mar 2018|Apr 2018|May 2018|Jun 2018|2017).*$/i, status: "confirmed" } 
    ]

    jenkins_list = [
      { issue_type: "jenkins_exposed_path", path: "/view/All/builds", severity: 4, body_regex: /Jenkins ver./i, status: "confirmed" },
      { issue_type: "jenkins_exposed_path", path: "/view/All/newjob",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { issue_type: "jenkins_exposed_path", path: "/asynchPeople/",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { issue_type: "jenkins_exposed_path", path: "/userContent/",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { issue_type: "jenkins_exposed_path", path: "/computer/",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { issue_type: "jenkins_exposed_path", path: "/pview/",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { issue_type: "jenkins_exposed_path", path: "/systemInfo",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { issue_type: "jenkins_exposed_path", path: "/script",  severity: 4, body_regex: /Jenkins/i, status: "confirmed" },
      { issue_type: "jenkins_exposed_path", path: "/signup",  severity: 5, body_regex: /Jenkins/i, status: "confirmed" },
      { issue_type: "jenkins_exposed_path", path: "/securityRealm/createAccount", severity: 4, body_regex: /Jenkins/i , status: "confirmed"}
    ]

    jforum_list = [ # CVE-2019-7550
      { issue_type: "jforum_info_leak", path: "/register/check/username?username=thisaccountdoesntexist", severity: 4,
          body_regex: /^true$/i, status: "confirmed" } # CVE-2019-7550
    ] 

    jira_list = [ # https://x.x.x.x?filterView=popular
      { issue_type: "jira_managefilters_info_leak", path: "/secure/ManageFilters.jspa", severity: 3,
          body_regex: /<title>Manage Filters/i, status: "confirmed" },
      { issue_type: "jira_2fa_bypass", path: "/login.action?nosso", severity: 3,
        body_regex: //i, status: "confirmed" } 
    ]
    # 
    joomla_list = [   # https://packetstormsecurity.com/files/151619/Joomla-Agora-4.10-Bypass-SQL-Injection.html
      { issue_type: "vulnerable_joomla", path: "/index.php?option=com_agora&task='", severity: 2, status: "potential" } 
    ] 

    lotus_domino_list = [
      { issue_type: "domino_info_leak", path: "/$defaultview?Readviewentries", severity: 3, body_regex: /\<viewentries/, status: "confirmed" }
    ]

    php_list =[
      { issue_type: "php_info_leak", path: "/phpinfo.php", severity: 4, body_regex: /<title>phpinfo\(\)/, status: "confirmed" }
    ]

    php_my_admin_list = [
      { issue_type: "vulnerable_php_my_admin", path: "/phpMyAdmin/scripts/setup.php", severity: 4, body_regex: nil, status: "potential" }
    ]

    # https://know.bishopfox.com/blog/breaching-the-trusted-perimeter
    pulse_secure_list = [
      { issue_type: "pulse_secure_info_leak", path: "/dana-na/nc/nc_gina_ver.txt", severity: 3, body_regex: /classid/, status: "confirmed" }, # CVE-2019-11510
      { issue_type: "vulnerable_pulse_secure", path: "/dana-na/../dana/html5acc/guacamole/../../../../../../etc/passwd?/dana/html5acc/guacamole/", severity: 1, body_regex: nil, status: "confirmed" },
      #{ path: "/dana-na/../dana/html5acc/guacamole/../../../../../../data/runtime/mtmp/system?/dana/html5acc/guacamole/", severity: 1, body_regex: nil, status: "potential" },
      #{ path: "/dana-na/../dana/html5acc/guacamole/../../../../../../data/runtime/mtmp/lmdb/dataa/data.mdb?/dana/html5acc/guacamole/", severity: 1, body_regex: nil, status: "potential" },
      #{ path: "/dana-na/../dana/html5acc/guacamole/../../../../../../data/runtime/mtmp/lmdb/randomVal/data.mdb?/dana/html5acc/guacamole/", severity: 1, body_regex: nil, status: "potential" }
    ]

    sap_netweaver_list =[ 
      { issue_type: "netweaver_info_leak", path: "/webdynpro/dispatcher/sap.com/caf~eu~gp~example~timeoff~wd/ACreate", 
        severity: 3, body_regex: /data-sap-ls-system-platform/, status: "confirmed" }, # https://www.exploit-db.com/exploits/44647
      { issue_type: "netweaver_info_leak", path: "/webdynpro/dispatcher/sap.com/caf~eu~gp~example~timeoff~wd/com.sap.caf.eu.gp.example.timeoff.wd.create.ACreate", 
        severity: 3, body_regex: /data-sap-ls-system-platform/, status: "confirmed" }, # https://www.exploit-db.com/exploits/44647
    ]

    sharepoint_list = [ 
      { issue_type: "sharepoint_info_leak", path: "/_vti_bin/spsdisco.aspx", body_regex: /\<discovery/, status: "confirmed" },
      { issue_type: "sharepoint_info_leak", path: "/_vti_bin/sites.asmx?wsdl", severity: 4, status: "potential" },
      { issue_type: "sharepoint_info_leak", path: "/_vti_pvt/service.cnf", body_regex: /vti_encoding/, status: "confirmed" },
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
      { issue_type: "splunk_info_leak", path: "/en-US/splunkd/__raw/services/server/info/server-info?output_mode=json", 
        body_regex: /os_name_extended/, severity: 4, status: "confirmed" }, # CVE-2018-11409
    ]

    # https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Insecure%20Management%20Interface
    spring_boot_list =[
      { issue_type: "spring_info_leak", path: "/trace", severity: 4, body_regex: nil, status: "potential" },
      { issue_type: "spring_info_leak", path: "/env", severity: 4, body_regex: nil, status: "potential" },
      { issue_type: "spring_info_leak", path: "/heapdump", severity: 4, body_regex: nil, status: "potential" },
      { issue_type: "spring_info_leak", path: "/actuator/env", severity: 4, body_regex: nil, status: "potential" },
      { issue_type: "spring_info_leak", path: "/actuator/health", severity: 4, body_regex: nil, status: "potential" },
    ] # more: https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Insecure%20Management%20Interface/Intruder/springboot_actuator.txt

    tomcat_list = [ 
      { issue_type: "tomcat_info_leak", path: '/status', severity: 4, body_regex: /<p> Free memory:/ },
      { issue_type: "tomcat_config", path: '/web-console', severity: 4, body_regex: nil },
      { issue_type: "vulnerable_tomcat", path: '/jmx-console', severity: 4, body_regex: nil },
      { issue_type: "tomcat_config", path: '/admin-console', severity: 4, body_regex: nil },
      { issue_type: "tomcat_config", path: '/manager/html', severity: 4, body_regex: nil },
      { issue_type: "tomcat_config", path: '/tomcat/manager/html', severity: 4, body_regex: nil },
      { issue_type: "tomcat_config", path: '/host-manager/html', severity: 4, body_regex: nil },
      { issue_type: "tomcat_config", path: '/server-manager/html', severity: 4, body_regex: nil },
      { issue_type: "vulnerable_tomcat", path: '/web-console/Invoker', severity: 4, body_regex: nil },
      { issue_type: "vulnerable_tomcat", path: '/jmx-console/HtmlAdaptor', severity: 4, body_regex: nil },
      { issue_type: "vulnerable_tomcat", path: '/invoker/JMXInvokerServlet', severity: 4, body_regex: nil}
      # http://[host]:8090/invoker/EJBInvokerServlet
      # https://[host]:8453//invoker/EJBInvokerServlet
      #{ path: '/invoker/EJBInvokerServlet', severity: 4,  body_regex: nil} 
    ]

    # VMware Horizon
    vmware_horizon_list = [
      { issue_type: "vmware_horizon_info_leak", path: "/portal/info.jsp", severity: 4, body_regex: /clientIPAddress/, status: "confirmed" } # CVE-2019-5513
    ]

    # Oracle Weblogic Server
    #  - CVE-2017-10271
    #  - April 2019 0day: http://bit.ly/2ZxYIjS
    weblogic_list = [
      { issue_type: "vulnerable_weblogic", path: "/wls-wsat/CoordinatorPortType", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" },
      { issue_type: "vulnerable_weblogic", path: "/wls-wsat/RegistrationPortTypeRPC", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" },
      { issue_type: "vulnerable_weblogic", path: "/wls-wsat/ParticipantPortType", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" }, 
      { issue_type: "vulnerable_weblogic", path: "/wls-wsat/RegistrationRequesterPortType", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" },
      { issue_type: "vulnerable_weblogic", path: "/wls-wsat/CoordinatorPortType11", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" },
      { issue_type: "vulnerable_weblogic", path: "/wls-wsat/RegistrationPortTypeRPC11", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" }, 
      { issue_type: "vulnerable_weblogic", path: "/wls-wsat/ParticipantPortType11", severity: 3, body_regex: /<td>WSDL:/,status: "confirmed" }, 
      { issue_type: "vulnerable_weblogic", path: "/wls-wsat/RegistrationRequesterPortType11", severity: 3, body_regex: /<td>WSDL:/, status: "confirmed" }
    ]

    websphere_list = [
      { issue_type: "websphere_info_leak", path: "/AddressBookJ2WB", severity: 5, status: "potential" },
      { issue_type: "websphere_info_leak", path: "/AddressBookJ2WE/services/AddressBook", severity: 5, status: "potential" },
      { issue_type: "websphere_info_leak", path: "/AlbumCatalogWeb", severity: 5, status: "potential" },
      { issue_type: "websphere_info_leak", path: "/AppManagementStatus", severity: 5, status: "potential" }
    ] # see more at https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/websphere.txt

    wordpress_list = [
      { issue_type: "wordpress_config_leak", path: "/wp-config.php~", severity: 1,  body_regex: /DB_PASSWORD/, status: "confirmed" },
      { issue_type: "wordpress_config_leak", path: "/wp-config.php.bak", severity: 1,  body_regex: /DB_PASSWORD/, status: "confirmed" },
      { issue_type: "wordpress_config_leak", path: "/wp-config.php_bak", severity: 1,  body_regex: /DB_PASSWORD/, status: "confirmed" },
      { issue_type: "wordpress_config_leak", path: "/wp-config.php.old", severity: 1,  body_regex: /DB_PASSWORD/, status: "confirmed" },
      { issue_type: "wordpress_config_leak", path: "/wp-config.php.save", severity: 1,  body_regex: /DB_PASSWORD/, status: "confirmed" },    
      { issue_type: "wordpress_config_leak", path: "/wp-config.php.orig", severity: 1,  body_regex: /DB_PASSWORD/, status: "confirmed" },
      { issue_type: "wordpress_config_leak", path: "/wp-config.php.original", severity: 1,  body_regex: /DB_PASSWORD/, status: "confirmed" },
      { issue_type: "wordpress_debug_log_leak", path: "/wp-content/debug.log", severity: 2,  header_regex: /text\/plain/, status: "confirmed" },      
      { issue_type: "wordpress_user_info_leak", path: '/wp-json/wp/v2/users', severity: 4,  body_regex: /slug/, status: "confirmed" }, 
      { issue_type: "wordpress_admin_login_exposed", path: '/wp-admin', severity: 5,  body_regex: /Powered by WordPress/, status: "confirmed" },
      { issue_type: "wordpress_api_exposed", path: '/xmlrpc.php', severity: 5, status: "confirmed", body_regex: /XML-RPC server accepts POST requests only./ }
      #{ path: '/wp-login.php?action=register', severity: 4, status: "potential"} # "User registration is currently not allowed."

      # TODO - look for "1.3.9.1" to disprove vulnerability 
      #{ path: '/wp-content/plugins/easy-wp-smtp/readme.txt', severity: 1,  body_regex: /Easy WP SMTP/i, status: "potential" },  
      #{ path: '/wp-content/plugins/easy-wp-smtp/css/style.css', severity: 2,  body_regex: /swpsmtp_settings_form/i, status: "potential" },  
      #{ path: '/wp-content/plugins/easy-wp-smtp/', severity: 2,  body_regex: /debug_log/i, status: "potential" },
      #{ path: '/wp-content/plugins/easy-wp-smtp/inc/', severity: 2,  body_regex: /debug_log/i, status: "potential" }
    ] 
  
    # Create our queue of work from the checks in brute_list
    work_q = Queue.new
    
    #  first handle our specific here (more likely to be interesting)
    apache_list.each { |x| work_q.push x } if is_product?(fingerprint,"HTTP Server")  # Apache
    asp_net_list.each { |x| work_q.push x } if ( 
      is_product?(fingerprint,"ASP.NET") || is_product?(fingerprint,"ASP.NET MVC") )
    coldfusion_list.each { |x| work_q.push x } if is_product?(fingerprint,"Coldfusion") 
    globalprotect_list.each { |x| work_q.push x } if is_product?(fingerprint,"GlobalProtect")
    jenkins_list.each { |x| work_q.push x } if is_product?(fingerprint,"Jenkins")
    jforum_list.each { |x| work_q.push x } if is_product?(fingerprint,"Jforum")
    jira_list.each { |x| work_q.push x } if is_product?(fingerprint,"Jira")
    joomla_list.each { |x| work_q.push x } if is_product?(fingerprint,"Joomla!")
    lotus_domino_list.each { |x| work_q.push x } if is_product?(fingerprint,"Domino")
    php_list.each { |x| work_q.push x } if is_product?(fingerprint,"PHP")
    php_my_admin_list.each { |x| work_q.push x } if is_product?(fingerprint,"phpMyAdmin")
    pulse_secure_list.each { |x| work_q.push x } if is_product?(fingerprint,"Junos Pulse Secure Access Service")
    sharepoint_list.each { |x| work_q.push x } if is_product?(fingerprint,"Sharepoint")
    sap_netweaver_list.each { |x| work_q.push x } if is_product?(fingerprint,"NetWeaver")
    splunk_list.each {|x| work_q.push x } if is_product?(fingerprint,"Splunk")
    spring_boot_list.each { |x| work_q.push x } if is_product?(fingerprint,"Spring Boot")
    spring_boot_list.each { |x| work_q.push x } if is_product?(fingerprint,"Spring Framework")
    tomcat_list.each { |x| work_q.push x } if is_product?(fingerprint,"Tomcat") 
    vmware_horizon_list.each { |x| work_q.push x } if is_product?(fingerprint,"Horizon View")
    weblogic_list.each { |x| work_q.push x } if is_product?(fingerprint,"Weblogic Server")
    websphere_list.each { |x| work_q.push x } if is_product?(fingerprint,"WebSphere")
    wordpress_list.each { |x| work_q.push x } if is_product?(fingerprint,"Wordpress") 

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



