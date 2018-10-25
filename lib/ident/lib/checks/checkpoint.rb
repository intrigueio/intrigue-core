module Intrigue
module Ident
module Check
  class Checkpoint < Intrigue::Ident::Check::Base

    def generate_checks(url)
      [
        {
          :type => "application",
          :vendor => "Checkpoint",
          :tags => ["vpn"],
          :product =>"GO",
          :match_details =>"page title",
          :references => ["https://en.wikipedia.org/wiki/Check_Point_GO"],
          :version => nil,
          :match_type => :content_body,
          :match_content =>  /<title>Check Point Mobile GO/i,
          :examples => ["http://192.234.138.61:80"],
          :verify => ["eGNlbGVuZXJneSNJbnRyaWd1ZTo6RW50aXR5OjpVcmkjaHR0cDovLzE5Mi4yMzQuMTM4LjYxOjgw"],
          :paths => ["#{url}"]
        },
        {
          :type => "application",
          :vendor => "Checkpoint",
          :tags => ["vpn"],
          :product =>"GO",
          :match_details =>"server header",
          :references => ["https://en.wikipedia.org/wiki/Check_Point_GO"],
          :version => nil,
          :match_type => :content_headers,
          :match_content =>  /server: CPWS/i,
          :examples => ["http://200.142.200.1:80"],
          :verify => ["aWJtI0ludHJpZ3VlOjpFbnRpdHk6OlVyaSNodHRwOi8vMjAwLjE0Mi4yMDAuMTo4MA=="],
          :paths => ["#{url}"]
        },
        {
          :type => "application",
          :vendor => "Checkpoint",
          :tags => ["vpn"],
          :product =>"SSL Network Extender",
          :match_details =>"server header",
          :references => [],
          :version => nil,
          :match_type => :content_headers,
          :match_content =>  /server: Check Point SVN foundation/i,
          :examples => ["https://www.cora.ro:8443"],
          :verify => ["aWJtI0ludHJpZ3VlOjpFbnRpdHk6OlVyaSNodHRwczovL3d3dy5jb3JhLnJvOjg0NDM="],
          :paths => ["#{url}"]
        }
      ]
    end
  end
end
end
end
