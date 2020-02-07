require "resolv"
module Intrigue
module Task
class SearchBlcheckList < BaseTask


  def self.metadata
    {
      :name => "search_blcheck_list",
      :pretty_name => "Search Blcheck List",
      :authors => ["Anas Ben Salah"],
      :description => "This task Test any domain against more then 100 black lists.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress","Domain"],
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => []
    }
  end


  ## Default method, subclasses must override this
  def run
    super
    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    # Blacklists to check
    blacklists=[
      "0spam-killlist.fusionzero.com",
      "0spam.fusionzero.com",
      "access.redhawk.org",
      "all.rbl.jp",
      "all.spam-rbl.fr",
      "all.spamrats.com",
      "aspews.ext.sorbs.net",
      "b.barracudacentral.org",
      "backscatter.spameatingmonkey.net",
      "badnets.spameatingmonkey.net",
      "bb.barracudacentral.org",
      "bl.drmx.org",
      "bl.konstant.no",
      "bl.nszones.com",
      "bl.spamcannibal.org",
      "bl.spameatingmonkey.net",
      "bl.spamstinks.com",
      "black.junkemailfilter.com",
      "blackholes.five-ten-sg.com",
      "blackholes.five-ten-sg.com",
      "blacklist.sci.kun.nl",
      "blacklist.woody.ch",
      "bogons.cymru.com",
      "bsb.empty.us",
      "bsb.spamlookup.net",
      "cart00ney.surriel.com",
      "cbl.abuseat.org",
      "cbl.anti-spam.org.cn",
      "cblless.anti-spam.org.cn",
      "cblplus.anti-spam.org.cn",
      "cdl.anti-spam.org.cn",
      "cidr.bl.mcafee.com",
      "combined.rbl.msrbl.net",
      "db.wpbl.info",
      "dev.null.dk",
      "dialups.visi.com",
      "dnsbl-0.uceprotect.net",
      "dnsbl-1.uceprotect.net",
      "dnsbl-2.uceprotect.net",
      "dnsbl-3.uceprotect.net",
      "dnsbl.anticaptcha.net",
      "dnsbl.aspnet.hu",
      "dnsbl.inps.de",
      "dnsbl.justspam.org",
      "dnsbl.kempt.net",
      "dnsbl.madavi.de",
      "dnsbl.rizon.net",
      "dnsbl.rv-soft.info",
      "dnsbl.rymsho.ru",
      "dnsbl.sorbs.net",
      "dnsbl.zapbl.net",
      "dnsrbl.swinog.ch",
      "dul.pacifier.net",
      "dyn.nszones.com",
      "dyna.spamrats.com",
      "fnrbl.fast.net",
      "fresh.spameatingmonkey.net",
      "hostkarma.junkemailfilter.com",
      "images.rbl.msrbl.net",
      "ips.backscatterer.org",
      "ix.dnsbl.manitu.net",
      "korea.services.net",
      "l2.bbfh.ext.sorbs.net",
      "l3.bbfh.ext.sorbs.net",
      "l4.bbfh.ext.sorbs.net",
      "list.bbfh.org",
      "list.blogspambl.com",
      "mail-abuse.blacklist.jippg.org",
      "netbl.spameatingmonkey.net",
      "netscan.rbl.blockedservers.com",
      "no-more-funn.moensted.dk",
      "noptr.spamrats.com",
      "orvedb.aupads.org",
      "pbl.spamhaus.org",
      "phishing.rbl.msrbl.net",
      "pofon.foobar.hu",
      "psbl.surriel.com",
      "rbl.abuse.ro",
      "rbl.blockedservers.com",
      "rbl.dns-servicios.com",
      "rbl.efnet.org",
      "rbl.efnetrbl.org",
      "rbl.iprange.net",
      "rbl.schulte.org",
      "rbl.talkactive.net",
      "rbl2.triumf.ca",
      "rsbl.aupads.org",
      "sbl-xbl.spamhaus.org",
      "sbl.nszones.com",
      "sbl.spamhaus.org",
      "short.rbl.jp",
      "spam.dnsbl.anonmails.de",
      "spam.pedantic.org",
      "spam.rbl.blockedservers.com",
      "spam.rbl.msrbl.net",
      "spam.spamrats.com",
      "spamrbl.imp.ch",
      "spamsources.fabel.dk",
      "st.technovision.dk",
      "tor.dan.me.uk",
      "tor.dnsbl.sectoor.de",
      "tor.efnet.org",
      "torexit.dan.me.uk",
      "truncate.gbudb.net",
      "ubl.unsubscore.com",
      "uribl.spameatingmonkey.net",
      "urired.spameatingmonkey.net",
      "virbl.dnsbl.bit.nl",
      "virus.rbl.jp",
      "virus.rbl.msrbl.net",
      "vote.drbl.caravan.ru",
      "vote.drbl.gremlin.ru",
      "web.rbl.msrbl.net",
      "work.drbl.caravan.ru",
      "work.drbl.gremlin.ru",
      "wormrbl.imp.ch",
      "xbl.spamhaus.org",
      "zen.spamhaus.org"
    ]

    # Initialisation
    dns_obj = Resolv::DNS.new()
    f = []

    # Check IP if they are listed in one of 117 blacklists
    if entity_type == "IpAddress"
      # Set the issue type
      issue_type = "malicious_ip"
      inves = entity_name
      check_blcheck inves, dns_obj, blacklists, issue_type
    elsif entity_type == "Domain"
      # Set the issue type
      issue_type = "malicious_domain"
      # Resolv domin name address
      inves = dns_obj.getaddress(entity_name)
      check_blcheck inves, dns_obj, blacklists, issue_type
    else
      _log_error "Unsupported entity type"
    end

  end #run

  # Check the BlackLists database for suspicious or malicious IP addresses or domains
  def check_blcheck inves, dns_obj, blacklists, issue_type
    # Reverse the IP to match the Dbl rules for checks
    revip = inves.to_s.split(/\./).reverse.join(".")
    # Perform nslookup vs every bl in the list
    blacklists.each do |e|
      query = revip +"."+ e
      f = dns_obj.getaddresses(query)
      # Getting multiple addresses results from the nslookup
      f.each do |i|
        # Investigate if the response is similar to 127.0.0. # for confirming the listing
        if i.to_s.include? "127."
          # Get the source of the blocker
          source = e
          # Create an issue if the IP is blacklisted
          _create_linked_issue(issue_type, {
            status: "confirmed",
            description: "This IP was founded related to malicious activities",
            proof: "This IP was founded flaged in #{e} blacklist",
            source: source
          })
          # Also store it on the entity
          blocked_list = @entity.get_detail("detected_malicious") || []
          @entity.set_detail("detected_malicious", blocked_list.concat([{source: source}]))
        end
      end
    end
  end

end
end
end
