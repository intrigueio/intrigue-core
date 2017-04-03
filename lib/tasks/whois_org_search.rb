require 'nokogiri'

module Intrigue
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
        {"type" => "String", "attributes" => {"name" => "Intrigue"}}
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
        puts "Working on #{org.text}"
        net_list_doc = Nokogiri::XML(http_get_body("#{org.text}/nets"))

        begin
          nets = net_list_doc.xpath("//xmlns:netRef")
          nets.children.each do |net_uri|
            puts "[!] Net: #{net_uri}" if net_uri

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

              puts "Creating net block: #{start_address}/#{cidr_length}"
              entity = _create_entity "NetBlock", {
                "name" => "#{start_address}/#{cidr_length}",
                "start_address" => "#{start_address}",
                "end_address" => "#{end_address}",
                "cidr" => "#{cidr_length}",
                "description" => "#{description}",
                "block_type" => "#{type}"
              }

            end # end netblocks.children
          end # end nets.children

        rescue Nokogiri::XML::XPath::SyntaxError => e
          puts " [x] No nets for #{org.text}"
        end

      end # end orgs.children

    rescue Nokogiri::XML::XPath::SyntaxError => e
      puts " [x] No orgs!"
    end

  end # end run

end
end
