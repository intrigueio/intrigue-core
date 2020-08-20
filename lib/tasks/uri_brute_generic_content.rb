module Intrigue
  module Task
  class UriBruteGenericContent < BaseTask
  
    def self.metadata
      {
        :name => "uri_brute_generic_content",
        :pretty_name => "URI Brute Generic Content",
        :authors => ["jcran"],
        :description => "Check for content common to web and application servers",
        :references => [],
        :type => "discovery",
        :passive => false,
        :allowed_types => ["Uri"],
        :example_entities => [
          {"type" => "Uri", "details" => {"name" => "http://intrigue.io"}}
        ],
        :allowed_options => [
          {:name => "threads", regex: "integer", :default => 1 },
        ],
        :created_types => ["Uri"]
      }
    end
  
    def run
      super
  
      uri = _get_entity_name
      opt_threads = _get_option("threads")
    
      generic_list = [
        #{ path: "/api", body_regex: nil },
        { issue_type: "exposed_vc_repository", path: "/.git", severity: 2, body_regex: /<h1>Index of/, status: "confirmed" },
        { issue_type: "exposed_vc_repository", path: "/.git/config", severity: 2, body_regex: /repositoryformatversion/, :status => "confirmed"  },
        { issue_type: "exposed_vc_repository", path: "/.hg", severity: 2, body_regex: /<h1>Index of/, status: "confirmed"  },
        { issue_type: "exposed_vc_repository", path: "/.bzr", severity: 2, body_regex: /<h1>Index of/, status: "confirmed" },
        { issue_type: "exposed_vc_repository_svn", path: "/.svn", severity: 2, body_regex: /<h1>Index of/, status: "confirmed"  },
        { issue_type: "exposed_vc_repository_svn", path: "/.svn/entries", severity: 2, body_regex: /^dir|\.svn-base|has-props$/, status: "confirmed" },
        { issue_type: "exposed_vc_repository_svn", path: "/.svn/prop-base", severity: 2, body_regex: /^dir|\.svn-base|has-props$/, status: "confirmed" },
        { issue_type: "exposed_vc_repository_svn", path: "/.svn/text-base", severity: 2, body_regex: /^dir|\.svn-base|has-props$/, status: "confirmed" },
        
        { issue_type: "htaccess_info_leak", path: "/.htaccess", body_regex: /AuthName/, severity: 3, status: "confirmed" },
        { issue_type: "htaccess_info_leak", path: "/.htaccess.bak", body_regex: /AuthName/, severity: 3, status: "confirmed" },
  
        # TODO - TOO NOISY :[
        #{ issue_type: "htpasswd", path: "/.htpasswd", body_regex: /(:\$|:\{.*\n|[a-z]:.*$)/, severity: 1, status: "confirmed" },
  
        #{ path: "/.csv", body_regex: /<h1>Index of/ },
        #{ path: "/.bak", body_regex: /<h1>Index of/ },
        #{ path: "/crossdomain.xml", body_regex: /\<cross-domain-policy/, severity: 6, status: "confirmed"}, #tighten regex?
        #{ path: "/clientaccesspolicy.xml", body_regex: /\<access-policy/, severity: 6, status: "confirmed"}, #tighten regex?
        #{ path: "/portal", body_regex: nil },
        #{ path: "/admin", body_regex: nil },
        #{ path: "/test", body_regex: nil },
      ]
  
      # Create our queue of work from the checks in brute_list
      work_q = Queue.new
  
      # then add our list:
      generic_list.each { |x| work_q.push x }
  
      ###
      ### Do the work
      ###
      results = make_http_requests_from_queue(uri, work_q, opt_threads, opt_create_url, true) # always create an issue
  
      _log "Got matches: #{results}"
  
    end # end run method
  
  end
  end
  end
  