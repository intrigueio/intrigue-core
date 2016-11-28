require 'whois'
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

    #
    # Set up & make the query
    #

    ###
    ### XXX - doesn't currently respect the timeout
    ###

    lookup_string = _get_entity_name

    begin
      whois = Whois::Client.new(:timeout => 20)
      answer = whois.lookup(lookup_string)
    rescue Whois::Error => e
      _log "Unable to query whois: #{e}"
    rescue Whois::ResponseIsThrottled => e
      _log "Got a response throttled message: #{e}"
      sleep 10
      return run # retry
    rescue StandardError => e
      _log "Unable to query whois: #{e}"
    rescue Exception => e
      _log "UNKNOWN EXCEPTION! Unable to query whois: #{e}"
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
      # if it was a domain, we've got a whole lot of shit we can scoop
      #
      if @entity.type_string == "DnsRecord"
        #
        # We're going to have nameservers either way?
        #
        if answer.nameservers
          answer.nameservers.each do |nameserver|
            #
            # If it's an ip address, let's create a host record
            #
            if nameserver.to_s =~ /\d\.\d\.\d\.\d/
              _create_entity "IpAddress", "name" => nameserver.to_s
              _create_entity "DnsServer", "name" => nameserver.to_s
            else
              #
              # Otherwise it's another domain, and we can't do much but add it
              #
              _create_entity "DnsRecord", "name" => nameserver.to_s

              # Resolve the name
              begin
                ip_address = IPSocket::getaddress(nameserver.to_s)
                _create_entity "IpAddress", "name" => ip_address
                _create_entity "DnsServer", "name" => ip_address
              rescue SocketError => e
                  _log "Unable to look up host: #{e}"
              end
            end
          end
        end

        #
        # Set the record properties
        #
        #@entity.disclaimer = answer.disclaimer
        #@entity.domain = answer.domain
        #@entity.referral_whois = answer.referral_whois
        #@entity.status = answer.status
        #@entity.registered = answer.registered?
        #@entity.available = answer.available?
        #if answer.registrar
        #  @entity.registrar_name = answer.registrar.name
        #  @entity.registrar_org = answer.registrar.organization
        #  @entity.registrar_url = answer.registrar.url
        #end
        #@entity.record_created_on = answer.created_on
        #@entity.record_updated_on = answer.updated_on
        #@entity.record_expires_on = answer.expires_on
        #@entity.full_text = answer.parts.first.body

        #
        # Create a user from the technical contact
        #
        begin
          if answer.technical_contact
            _log "Creating user from technical contact"
            _create_entity("Person", {"name" => answer.technical_contact.name})
          end
        rescue Exception => e
          _log "Unable to grab technical contact"
        end

        #
        # Create a user from the admin contact
        #
        begin
          if answer.admin_contact
            _log "Creating user from admin contact"
            _create_entity("Person", {"name" => answer.admin_contact.name})
          end
        rescue Exception => e
          _log "Unable to grab admin contact"
        end

        #
        # Create a user from the registrant contact
        #
        begin
          if answer.registrant_contact
            _log "Creating user from registrant contact"
            _create_entity("Person", {:name => answer.registrant_contact.name})
          end
        rescue Exception => e
          _log "Unable to grab registrant contact"
        end

        # @entity.save!


      else

        #
        # Otherwise our entity must've been a host
        #

        #
        # Parse out the netrange - WARNING SUPERJANKYNESS ABOUND
        #
        # Format:
        #
        # <?xml version='1.0'?>
        # <?xml-stylesheet type='text/xsl' href='http://whois.arin.net/xsl/website.xsl' ?>
        # <net xmlns="http://www.arin.net/whoisrws/core/v1" xmlns:ns2="http://www.arin.net/whoisrws/rdns/v1" xmlns:ns3="http://www.arin.net/whoisrws/netref/v2" termsOfUse="https://www.arin.net/whois_tou.html">
        #  <registrationDate>2009-09-21T17:15:11-04:00</registrationDate>
        #  <ref>http://whois.arin.net/rest/net/NET-8-8-8-0-1</ref>
        #  <endAddress>8.8.8.255</endAddress>
        #  <handle>NET-8-8-8-0-1</handle>
        #  <name>LVLT-GOOGL-1-8-8-8</name>
        #  <netBlocks><netBlock>
        #  <cidrLength>24</cidrLength>
        #  <endAddress>8.8.8.255</endAddress>
        #  <description>Reassigned</description>
        #  <type>S</type>
        #  <startAddress>8.8.8.0</startAddress>
        #  </netBlock></netBlocks>
        #  <orgRef name="Google Incorporated" handle="GOOGL-1">http://whois.arin.net/rest/org/GOOGL-1</orgRef>
        #  <parentNetRef name="LVLT-ORG-8-8" handle="NET-8-0-0-0-1">http://whois.arin.net/rest/net/NET-8-0-0-0-1</parentNetRef>
        #  <startAddress>8.8.8.0</startAddress>
        #  <updateDate>2009-09-21T17:15:11-04:00</updateDate>
        #  <version>4</version>
        # </net>

        doc = Nokogiri::XML(http_get_body("http://whois.arin.net/rest/ip/#{lookup_string}"))
        org_ref = doc.xpath("//xmlns:orgRef").text
        parent_ref = doc.xpath("//xmlns:parentNetRef").text
        handle = doc.xpath("//xmlns:handle").text

        # For each netblock, create an entity
        doc.xpath("//xmlns:net/xmlns:netBlocks").children.each do |netblock|
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

      end # end Host Type

    else
      _log "Domain WHOIS failed, we don't know what nameserver to query."
    end

  end

end
end
