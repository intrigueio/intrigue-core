module Intrigue
module Ident
module Check
    class Oracle < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Oracle",
            :product =>"Application Server",
            :match_details =>"server header",
            :references => [],
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /Oracle-Application-Server/,
            :hide => false,
            :dynamic_version => lambda { |x|
                _first_header_capture(x,/Oracle-Application-Server-[0-9]+[a-z]?\/(.*?)\ /) },
            :examples => [
              "https://63.85.74.53:443",
              "https://rss.tomthumb.com:443",
              "https://qas.huntsmanservice.com:443"
            ],
            :verify => ["YWxiZXJ0c29ucyNJbnRyaWd1ZTo6RW50aXR5OjpVcmkjaHR0cHM6Ly9yc3MudG9tdGh1bWIuY29tOjQ0Mw=="],
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Oracle",
            :product =>"Fusion Middleware",
            :match_details =>"page title & docs link... should give us a version",
            :version => nil,
            :dynamic_version => lambda { |x|
              doc_version = _first_body_capture(x,/download.oracle.com\/docs\/cd\/(.*?)\/index.htm/)
              case doc_version
                when "E15217_01"
                  fmw_version = "10.1.4.3"
                when "E15051_01"
                  fmw_version = "11.1.1.0"
                when "E12839_01"
                  fmw_version = "11.1.1.1"
                when "E15523_01"
                  fmw_version = "11.1.1.2"
                when "E14571_01"
                  fmw_version = "11.1.1.3"
                when "E17904_01"
                  fmw_version = "11.1.1.4"
                when "E21764_01"
                  fmw_version = "11.1.1.5"
                else
                  fmw_version = nil
              end
            fmw_version
            },
            :match_type => :content_body,
            :references => [
              "https://en.wikipedia.org/wiki/Oracle_Fusion_Middleware",
              "https://docs.oracle.com/cd/E21764_01/index.htm"
            ],
            :match_content =>  /<title>Welcome to Oracle Fusion Middleware/,
            :hide => false,
            :examples => [
              "http://200.142.198.113:80"
            ],
            :verify => ["aWJtI0ludHJpZ3VlOjpFbnRpdHk6OlVyaSNodHRwOi8vMjAwLjE0Mi4xOTguMTEzOjgw"],
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Oracle",
            :product =>"Glassfish",
            :match_details =>"Oracle / Sun GlassFish Enterprise Server",
            :references => [],
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /Sun GlassFish Enterprise Server/,
            :hide => false,
            :dynamic_version => lambda { |x| _first_header_capture(x,/Sun GlassFish Enterprise Server\sv([\d\.]+)/) },
            :examples => ["http://52.4.12.185/"],
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Oracle",
            :product =>"Glassfish",
            :match_details =>"Oracle / Sun GlassFish Enterprise Server",
            :references => [],
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /GlassFish Server Open Source Edition/,
            :hide => false,
            :dynamic_version => lambda { |x| _first_header_capture(x,/GlassFish Server Open Source Edition\s+([\d\.]+)$/) },
            :examples => ["http://52.2.97.57:80"],
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Oracle",
            :product =>"HTTP Server",
            :match_details =>"server header",
            :references => [],
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /Oracle-HTTP-Server/,
            :hide => false,
            :dynamic_version => lambda { |x|
                _first_header_capture(x,/Oracle-HTTP-Server\/(.*?)\ /)
            },
            :examples => [
              "https://qas.huntsmanservice.com:443"
            ],
            :verify => ["aHVudHNtYW4jSW50cmlndWU6OkVudGl0eTo6VXJpI2h0dHBzOi8vcWFzLmh1bnRzbWFuc2VydmljZS5jb206NDQz"],
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Oracle",
            :product =>"Java",
            :match_details =>"JSESSIONID cookie",
            :references => ["https://javarevisited.blogspot.com/2012/08/what-is-jsessionid-in-j2ee-web.html"],
            :version => nil,
            :match_type => :content_cookies,
            :match_content =>  /JSESSIONID=/,
            :hide => false,
            :examples => ["https://birdcam.xcelenergy.com:443"],
            :paths => ["#{url}"]
          },
          { # TODO - this will tell us J2EE versions, see references!!!
            :type => "application",
            :vendor => "Oracle",
            :product =>"Java Application Server",
            :match_details =>"x-header",
            :references => ["http://www.ntu.edu.sg/home/ehchua/programming/java/javaservlets.html"],
            :version => nil,
            :dynamic_version => lambda { |x| _first_header_capture(x,/^x-powered-by: Servlet\/(.*)JSP.*$/) },
            :match_type => :content_headers,
            :match_content =>  /x-powered-by: Servlet/,
            :hide => false,
            :paths => ["#{url}"],
            :examples => ["http://165.160.15.20/"]
          },
          { # TODO - this will tell us J2EE versions, see references!!!
            :type => "application",
            :vendor => "Oracle",
            :product =>"Java Server Pages",
            :match_details =>"x-header",
            :references => ["http://www.ntu.edu.sg/home/ehchua/programming/java/javaservlets.html"],
            :version => nil,
            :dynamic_version => lambda { |x| _first_header_capture(x,/^x-powered-by: Servlet\/.*JSP\/(.*)$/) },
            :match_type => :content_headers,
            :match_content =>  /x-powered-by: Servlet\/.*JSP.*/,
            :hide => false,
            :paths => ["#{url}"],
            :examples => ["http://165.160.15.20/"]
          },
          {
            :type => "application",
            :vendor => "Oracle",
            :product =>"JavaServer Faces",
            :match_details =>"viewstate inclusion of javaserver faces",
            :references => [
              "http://www.oracle.com/technetwork/java/javaee/javaserverfaces-139869.html",
              "http://www.oracle.com/technetwork/topics/index-090910.html",
              "https://www.owasp.org/index.php/Java_Server_Faces",
              "https://www.alphabot.com/security/blog/2017/java/Misconfigured-JSF-ViewStates-can-lead-to-severe-RCE-vulnerabilities.html"
            ],
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /javax.faces.ViewState/,
            :hide => false,
            :examples => ["https://reset.oxy.com:443"],
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Oracle",
            :product =>"Web Cache Server",
            :match_details =>"server header",
            :references => [],
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /Oracle-Web-Cache/,
            :hide => false,
            :dynamic_version => lambda { |x|
                _first_header_capture(x,/Oracle-Web-Cache-[0-9]+[a-z]?\/(.*?)\ /) },
            :examples => [
              "https://qas.huntsmanservice.com:443"
            ],
            :verify => ["aHVudHNtYW4jSW50cmlndWU6OkVudGl0eTo6VXJpI2h0dHBzOi8vcWFzLmh1bnRzbWFuc2VydmljZS5jb206NDQz"],
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Oracle",
            :product =>"Weblogic",
            :match_details =>"weblogic fault / fail",
            :references => ["https://coderanch.com/t/603067/application-servers/Calling-weblogic-webservice-error"],
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /<faultcode>env:WebServiceFault/,
            :hide => false,
            :examples => ["https://css-ewebsvcs.freddiemac.com:443"],
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Oracle",
            :product =>"Weblogic",
            :match_details =>"weblogic header",
            :references => [
              "https://support.oracle.com/knowledge/Middleware/2100514_1.html",
              "https://www.qualogy.com/techblog/oracle/how-to-harden-weblogic-and-fusion-middleware-against-worm-attacks"
            ],
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /^x-oracle-dms-ecid:/,
            :hide => false,
            :examples => ["https://tmsstg-eem-db.ros.com:443"],
            :verify => ["cm9zc3N0b3JlcyNJbnRyaWd1ZTo6RW50aXR5OjpVcmkjaHR0cHM6Ly90bXNzdGctZWVtLWRiLnJvcy5jb206NDQz"],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
