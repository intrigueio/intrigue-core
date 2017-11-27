module Intrigue
module Task
class WhoisOrgSearch < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "whois_org_search",
      :pretty_name => "Whois Organization Search",
      :authors => ["jcran"],
      :description => "Perform a whois lookup for a given entity",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Organization", "String"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "Intrigue"}}
      ],
      :allowed_options => [
        {:name => "timeout", :type => "Integer", :regex=> "integer", :default => 20 }],
      :created_types => ["NetBlock"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    lookup_string = _get_entity_name.upcase

    begin
      search_doc = Nokogiri::XML(http_get_body("http://whois.arin.net/rest/orgs;name=#{URI.escape(lookup_string)}*"));nil
      orgs = search_doc.xpath("//xmlns:orgRef")

      # For each netblock, create an entity
      orgs.children.each do |org|
        _log_good "Working on #{org.text}"
        net_list_doc = Nokogiri::XML(http_get_body("#{org.text}/nets"))

        begin
          nets = net_list_doc.xpath("//xmlns:netRef")
          nets.children.each do |net_uri|
            _log_good "[!] Net: #{net_uri}" if net_uri

            #page = "https://whois.arin.net/rest/net/NET-64-41-230-0-1.xml"
            page = "#{net_uri}.xml"

            net_doc = Nokogiri::XML(http_get_body(page));nil
            net_blocks = net_doc.xpath("//xmlns:netBlocks");nil

            net_blocks.children.each do |n|
              start_address = n.css("startAddress").text
              end_address = n.css("endAddress").text
              description = n.css("description").text
              cidr_length = n.css("cidrLength").text
              type = n.css("type").text

              # Do a lookup - important that we get this so we can verify
              # if the block actually belongs to the expected party (via whois_full_text)
              # see discovery strategy for more info
              begin
                whois = ::Whois::Client.new(:timeout => 20)
                answer = whois.lookup(start_address)
                parser = answer.parser
                whois_full_text = answer.content if answer
              rescue ::Whois::ResponseIsThrottled => e
                _log "Unable to query whois: #{e}"
              end
              #===================================

              _log_good "Creating net block: #{start_address}/#{cidr_length}"
              entity = _create_entity "NetBlock", {
                "name" => "#{start_address}/#{cidr_length}",
                "start_address" => "#{start_address}",
                "end_address" => "#{end_address}",
                "cidr" => "#{cidr_length}",
                "description" => "#{description}",
                "block_type" => "#{type}",
                "whois_full_text" => "#{whois_full_text}"
              }

            end # end netblocks.children
          end # end nets.children

        rescue Nokogiri::XML::XPath::SyntaxError => e
          _log_error " [x] No nets for #{org.text}"
        end

      end # end orgs.children

    rescue Nokogiri::XML::XPath::SyntaxError => e
      _log_error " [x] No orgs!"
    end

  end # end run

end
end
end
