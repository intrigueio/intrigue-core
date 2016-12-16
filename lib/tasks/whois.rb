require 'whois'
require 'whois-parser'
require 'nokogiri'
require 'socket'

module Intrigue
class WhoisTask < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "whois",
      :pretty_name => "Whois",
      :authors => ["jcran"],
      :description => "Perform a whois lookup for a given entity",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord", "IpAddress","NetBlock"],
      :example_entities => [
        {"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}},
        {"type" => "IpAddress", "attributes" => {"name" => "192.0.78.13"}},
      ],
      :allowed_options => [
        {:name => "timeout", :type => "Integer", :regex=> "integer", :default => 20 }],
      :created_types => ["DnsRecord","DnsServer","IpAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    ###
    ### XXX - doesn't currently respect the timeout
    ###

    lookup_string = _get_entity_name

    begin
      whois = Whois::Client.new(:timeout => 20)
      answer = whois.lookup(lookup_string)
      parser = answer.parser
    #rescue Whois::ResponseIsThrottled => e
    #  _log "Got a response throttled message: #{e}"
    #  sleep 10
    #  return run # retry
    rescue StandardException => e
      _log "Unable to query whois: #{e}"
      return
    end

    #
    # Check first to see if we got an answer back
    #
    if answer

      # Log the full text of the answer
      _log "== Full Text: =="
      _log answer.content
      _log "================"

      #
      # if it was a domain, we've got a whole lot of things we can pull
      #
      if @entity.kind_of? Intrigue::Entity::DnsRecord

        #
        # We're going to have nameservers either way?
        #
        if parser.nameservers

          parser.nameservers.each do |nameserver|
            _log "Parsed nameserver: #{nameserver}"
            #
            # If it's an ip address, let's create a host record
            #
            if nameserver.to_s =~ /\d\.\d\.\d\.\d/
              _create_entity "IpAddress", "name" => nameserver.to_s
            else
              #
              # Otherwise it's another domain, and we can't do much but add it
              #
              _create_entity "DnsRecord", "name" => nameserver.to_s
            end
          end
        else
          _log_error "No parsed nameservers!"
          return
        end
        #
        # Create a user from the technical contact
        #
        parser.contacts.each do |contact|
          _log "Creating user from contact: #{contact.name}"
          _create_entity("Person", {"name" => contact.name})
          _create_entity("EmailAddress", {"name" => contact.email})
        end

      else

        #
        # Otherwise our entity must've been a host, so lets connect to
        # ARIN's API and fetch the details
        #

        begin
          doc = Nokogiri::XML(http_get_body("http://whois.arin.net/rest/ip/#{lookup_string}"))
          org_ref = doc.xpath("//xmlns:orgRef").text
          parent_ref = doc.xpath("//xmlns:parentNetRef").text
          handle = doc.xpath("//xmlns:handle").text

          # For each netblock, create an entity
          doc.xpath("//xmlns:netBlocks").children.each do |netblock|
            # Grab the relevant info

            cidr_length = ""
            start_address = ""
            end_address = ""
            block_type = ""
            description = ""

            netblock.children.each do |child|

              cidr_length = child.text if child.name == "cidrLength"
              start_address = child.text if child.name == "startAddress"
              end_address = child.text if child.name == "endAddress"
              block_type = child.text if child.name == "type"
              description = child.text if child.name == "description"

            end # End netblock children

            #
            # Create the netblock entity
            #
            entity = _create_entity "NetBlock", {
              "name" => "#{start_address}/#{cidr_length}",
              "start_address" => "#{start_address}",
              "end_address" => "#{end_address}",
              "cidr" => "#{cidr_length}",
              "description" => "#{description}",
              "block_type" => "#{block_type}",
              "handle" => "#{handle}",
              "organization_reference" => "#{org_ref}",
              "parent_reference" => "#{parent_ref}",
              "whois_full_text" => "#{answer.content}"
            }

          end # End Netblocks
        rescue Nokogiri::XML::XPath::SyntaxError => e
          _log_error "Got an error while parsing the XML: #{e}"
        end
      end # end Host Type

    else
      _log_error "Domain WHOIS failed, we don't know what nameserver to query."

    end

  end

end
end
