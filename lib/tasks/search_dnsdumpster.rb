module Intrigue
module Task
class SearchDNSdumpster < BaseTask
    def self.metadata
    {
        :name => "search_dnsdumpster",
        :pretty_name => "Search DNSdumpster",
        :authors => ["Xiao-Lei Xiao"],
        :description => "This task utilises the domain research tool DNSdumpster to research, find & lookup dns records. ",
        :references => ["https://dnsdumpster.com/"],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["Domain"],
        :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}},
        ],
        :allowed_options => [],
        :created_types => ['Domain', 'DnsRecord']
    }
    end

    ## Default method, subclasses must override this
    def run
        super
  
        entity_name = _get_entity_name
  
        begin
            response = http_request(:get, "https://dnsdumpster.com/", nil, {})
            cookie = response.headers["Set-Cookie"].match(/(.*?;){1}/)
            token = cookie.to_s.scan(/=(.+)[,;]$/)[0][0]

            response = http_post("https://dnsdumpster.com/", "csrfmiddlewaretoken=#{token}&targetip=#{entity_name}", {
                "Referer" =>  "https://dnsdumpster.com/" ,
                "Cookie" => "#{cookie}" 
            })
           
            doc = Nokogiri::HTML(response.body_utf8)
            subdomains = doc.css('table')[0].search('tr').map { |tr| tr.content.delete!("\n").split(" ")[0] }
            
            subdomains.each { |s| create_dns_entity_from_string(s) } unless subdomains.empty?
          end
  
    end #end run

end
end
end
