class HostToAsNumberTask < BaseTask

  ###
  ### XXX - This module cannot be publicly released without notifying the
  ###       Team Cymru organization. Do NOT release without doing this,
  ###       and remove this message when complete. (If you see this message),
  ###       please contact jcran@intrigue.io immediately!
  ###

  def metadata
    { 
      :name => "ip_address_to_as_number",
      :pretty_name => "IP Address to AS Number",
      :authors => ["jcran"],
      :description => "This task queries the Cymru IP2AS database.",
      :references => [
        "http://www.team-cymru.org/Services/ip-to-asn.html",
        "https://github.com/junv/cymruwhois"],
      :allowed_types => ["IpAddress"],
      :example_entities => [{:type => "IpAddress", :attributes => {:name => "8.8.8.8"}}],
      :allowed_options => [],
      :created_types => ["AsNumber"]

    }
  end

  ## Default method, subclasses must override this
  def run
    super

    ip_address = _get_entity_attribute "name"

    c = Client::Search::Cymru::IPAddress.new
    c.whois(ip_address)

    # result = [“27357”, “US”, “ARIN”, “2003-02-20”, “RACKSPACE - RACKSPACE HOSTING”]
    #:asnum, :cidr, :country, :registry, :allocdate, :asname

    _create_entity "AsNumber", {
      :number => c.asnum,
      :country => c.country,
      :cidr => c.cidr,
      :registry => c.registry,
      :allocated => c.allocdate,
      :name => c.asname
    }
  end

end
