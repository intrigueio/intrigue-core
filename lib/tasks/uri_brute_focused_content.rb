module Intrigue
module Task
class UriBruteFocusedContent < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_brute_focused_content",
      :pretty_name => "URI Brute Focused Content",
      :authors => ["jcran"],
      :description => "Check for pages specific to the site's technology. Supported Tech: ASP.net, Coldfusion, Tomcat",
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

    always_list = [ "/api", "/admin","/.git", "/.hg", "/.svn", "/.bzr", "/.csv", "/.bak", 
                    "/crossdomain.xml", "/clientaccesspolicy.xml", "/sitemap.xml",
                    "/portal","/admin","/test","/server-status" ]
                    # "/WS_FTP.LOG", "/ws_ftp.log"

    # technology specifics 
    asp_net_list = ["/elmah.axd", "/web.config", "/Trace.axd"]
    # /Trace.axd - /<h1>Request Details/

    coldfusion_list = ["/CFIDE", "CFIDE/administrator/enter.cfm" ] # TODO see metasploit for more ideas here

    tomcat_list = [ '/status', '/admin', '/web-console', '/jmx-console', '/admin-console', 
                    '/manager/html', '/tomcat/manager/html', '/host-manager/html', '/server-manager/html', 
                    '/web-console/Invoker', '/jmx-console/HtmlAdaptor', '/invoker/JMXInvokerServlet' ]

    wordpress_list = ["/wp-admin" ] # TODO see metasploit for more ideas here

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
        missing_page_test = :code
      when "200"
        missing_page_test = :content
        missing_page_content = response.body
      else
        missing_page_test = :code
        missing_page_code = response.code
    end

    # Create our queue of work from the checks in brute_list
    ##########################

    # first add our "always" stuff:
    work_q = Queue.new
    always_list.each { |path| work_q.push "#{uri}#{path}" }
    
    #  handle our specific here
    asp_net_list.each { |path| work_q.push "#{uri}#{path}" } if is_product?("ASP.NET") || is_product?("ASP.NET MVC")
    coldfusion_list.each { |path| work_q.push "#{uri}#{path}" } if is_product? "Coldfusion"  
    tomcat_list.each { |path| work_q.push "#{uri}#{path}" } if is_product? "Tomcat" 
    wordpress_list.each { |path| work_q.push "#{uri}#{path}" } if is_product? "Wordpress" 


    # Create a pool of worker threads to work on the queue
    workers = (0...opt_threads).map do
      Thread.new do
        begin
          while request_uri = work_q.pop(true)

            # Do the check
            result = check_uri_exists(request_uri, missing_page_test, missing_page_code, missing_page_content)

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
