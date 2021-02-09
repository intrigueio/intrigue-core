module Intrigue
  module Task
  class UriBruteWebPanels < BaseTask
  
    def self.metadata
      {
        :name => "uri_brute_web_panels",
        :pretty_name => "URI Brute Web Panels",
        :authors => ["jcran"],
        :description => "Check for commonly exposed web panels by requesting and checking the content."
        :references => [],
        :type => "vulnerability",
        :passive => false,
        :allowed_types => ["Uri"],
        :example_entities => [
          {"type" => "Uri", "details" => {"name" => "http://intrigue.io"}}
        ],
        :allowed_options => [
          {:name => "threads", regex: "integer", :default => 1 },
        ],
        :created_types => []
      }
    end
  
    def run
      super
  
      uri = _get_entity_name
      opt_threads = _get_option("threads")
  
      # technology specifics
      panel_check_list = [
        # solr-exposure
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/solr/", 
           body_regex: /\<title\>Solr Admin/i, severity: 4, status: "confirmed" },  
        # sonarqube-login
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/sessions/new", 
           body_regex: /\<title\>SonarQube/i, severity: 4, status: "confirmed" },            
        # sonicwall-management-panel
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/auth.html", 
           body_regex: /\<title\>SonicWall - Authentication/i, severity: 4, status: "confirmed" },            
        # sonicwall-sslvpn-panel
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/cgi-bin/welcome", 
           body_regex: /\<title\>Virtual Office/i, severity: 4, status: "confirmed" },    
        # sophos-fw-version-detect
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/userportal/webpages/myaccount/login.jsp", 
           body_regex: /\<title\>Sophos</i, severity: 4, status: "confirmed" },    
        # sophos-fw-version-detect
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/webconsole/webpages/login.jsp", 
           body_regex: /\<title\>Sophos</i, severity: 4, status: "confirmed" },    
        # generic admin panel-detect ### 
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/admin", 
           body_regex: /password/i, severity: 4, status: "confirmed" },  
        # generic admin panel-detect ### 
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/admin/signin", 
           body_regex: /password/i, severity: 4, status: "confirmed" },  
        # generic admin panel-detect ### 
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/admin/logon", 
           body_regex: /password/i, severity: 4, status: "confirmed" },  
        # generic admin panel-detect ### 
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/admin/login", 
           body_regex: /password/i, severity: 4, status: "confirmed" },  
        # supervpn-detect
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/admin/login.html", 
           body_regex: /\<title\>Sign In-SuperVPN/i, severity: 4, status: "confirmed" },        
        # tikiwiki-cms
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/tiki-login.php", 
           body_regex: /Tiki Wiki CMS Groupware/i, severity: 4, status: "confirmed" },
        # tikiwiki-cms
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/tiki-login_scr.php", 
           body_regex: /Tiki Wiki CMS Groupware/i, severity: 4, status: "confirmed" },
        # tomcat-manager ###
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/../manager/html", 
           body_regex: /manager-gui/i, severity: 4, status: "confirmed" },
        # tomcat-manager-pathnormalization
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/..;/host-manager/html", 
           body_regex: /manager-gui/i, severity: 4, status: "confirmed" },        
        # tomcat-manager-pathnormalization
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/..;/manager/html", 
           body_regex: /manager-gui/i, severity: 4, status: "confirmed" },        
        # traefik-dashboard-detect
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/dashboard/", 
            body_regex: /<meta name=description content=\"Traefik UI\">/i, severity: 4, status: "confirmed" },        
        # virtual-ema-detect
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/VirtualEms/Login.aspx", 
            body_regex: /Welcome Guest/i, severity: 4, status: "confirmed" },        
        # weave-scope-dashboard-detect
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/", 
            body_regex: /__WEAVEWORKS_CSRF_TOKEN/i, severity: 4, status: "confirmed" },        
        # webmin-panel
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/webmin", 
            body_regex: /\<title\>Login to Webmin/i, severity: 4, status: "confirmed" },    
        # webmin-panel
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/", 
            body_regex: /\<title\>Login to Webmin/i, severity: 4, status: "confirmed" },    
        # workspace-one-uem
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/AirWatch/Login", 
            body_regex: /About VMware AirWatch/i, severity: 4, status: "confirmed" },    
        # workspaceone-uem-airwatch-dashboard-detect
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/AirWatch/Login", 
            body_regex: /Workspace/i, severity: 4, status: "confirmed" },  
        # yarn-manager-exposure / Apache Yarn ResourceManager Exposure / Unauthenticated Access
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/cluster/cluster", 
            body_regex: /hadoop/i, severity: 4, status: "confirmed" },  
        # zipkin-exposure / Zipkin
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/zipkin/", 
            body_regex: /webpackJsonpzipkin-lens/i, severity: 4, status: "confirmed" },  
        # zipkin-exposure / Zipkin
        { issue_type: "exposed_admin_panel_unauthenticated", path: "/", 
            body_regex: /webpackJsonpzipkin-lens/i, severity: 4, status: "confirmed" }
      ]
  
      # Create our queue of work from the checks in brute_list
      work_q = Queue.new
  
      # put all the checks into a list 
      panel_check_list.each { |x| work_q.push x }
 
      ###
      ### Do the work
      ###
      results = make_http_requests_from_queue(uri, work_q, opt_threads, opt_create_url, true) # always create an issue
  
      _log "Got matches: #{results}"
  
    end # end run method
  
  end
  end
  end
  
