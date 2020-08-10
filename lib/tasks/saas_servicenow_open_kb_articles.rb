module Intrigue
module Task
class SaasServicenowOpenKbArticles < BaseTask

  def self.metadata
    {
      :name => "saas_servicenow_open_kb_articles",
      :pretty_name => "SaaS ServiceNow Open KB Articles",
      :authors => ["jcran", "Th3G3nt3lman", "LeoHildegarde"],
      :description => "Given a servicenow slug, this task checks to see if the " + 
        "account is exposed to the miconfiguration documented by Th3G3nt3lman in early June 2020. " + 
        "The misconfiguration allows KB articles to be bruteforced by guessing the last digits " +
        "of articles. The existence of an article results in an issue being created.",
      :references => [
        "https://medium.com/@th3g3nt3l/multiple-information-exposed-due-to-misconfigured-service-now-itsm-instances-de7a303ebd56",
        "https://github.com/leo-hildegarde/SnowDownKB"
      ],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["WebAccount"],
      :example_entities => [
        {"type" => "WebAccount", "details" => {"name" => "intrigue"}}
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    if _get_entity_type_string == "WebAccount"
      entity_name = _get_entity_detail("username")      
    else 
      entity_name = _get_entity_name
    end

    # first check if account exists 
    url = "https://#{entity_name}.service-now.com"
    body = http_get_body url
    if body
      _log_good "The #{entity_name} org exists, proceeding!"
    else 
      _log_error "No #{entity_name} org, cowardly refusing"
      return
    end

    # now brute if we made it
    brute_articles entity_name
  end


  def brute_articles(account_name)
    max_article_id = 20000
    article_id  = 1
    
    # shove our requests into a queue
    work_q = Queue.new
    (0..20000).step(100).reverse_each do |d| 
      
      # craft the URL 
      article_id = "KB00#{format('%04d',d)}"
      endpoint = "/kb_view_customer.do?sysparm_article=#{article_id}"
     
      ###
      ### TODO ... see regexes here: https://github.com/leo-hildegarde/SnowDownKB/blob/master/download_KBv001.sh
      ###

      # craft the request
      request = { 
        issue_type: "servicenow_open_kb_misconfig", 
        path: "#{endpoint}", 
        severity: 2,  
        body_regex: /Published/, 
        exclude_body_regex: /PROTECTED ARTICLE/, 
        status: "confirmed" 
      }

      work_q.push(request)
    end
    

    ###
    ### Do the work, threadded
    ###
    _log_good "Making #{work_q.size} requests"
    uri = "https://#{account_name}.service-now.com"
    results = make_http_requests_from_queue(uri, work_q, 3, true, true) # always create an issue
  end

end
end
end
