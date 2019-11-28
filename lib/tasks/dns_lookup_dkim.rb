module Intrigue
module Task
class DnsLookupDkim < BaseTask

  include Intrigue::Task::Dns

=begin
TODO implement issue creation for policy settings

When you use DomainKeys you can publish policy statements in DNS that help 
email receivers understand how they should treat your email. There are three 
main statements that can be published:

"t=y" - Which means that your email DomainKeys are in test mode.
"o=-" - All email from your domain is digitally signed.
"o=~" - Some email from your domain is digitally signed.
"n=*" - n stands for notes. Replace the * symbol, with any note you like
=end

  def self.metadata
    {
      :name => "dns_lookup_dkim",
      :pretty_name => "DNS DKIM Lookup",
      :authors => ["jcran"],
      :description => "Attempts to identify all known DKIM records by iterating through known selectors",
      :references => [
        "http://dkim.org/info/dkim-faq.html",
        "https://www.unlocktheinbox.com/resources/domainkeys/"
      ],
      :allowed_types => ["Domain","DnsRecord"],
      :type => "discovery",
      :passive => true,
      :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "create_domain", :regex => "boolean", :default => false },
      ],
      :created_types => ["DnsRecord", "Domain"]
    }
  end

  def run
    super

    domain_name = _get_entity_name

    _log "Running DKIM lookup on #{domain_name}"

    dkim_records = collect_dkim_records(domain_name)

    # always start out empty
    _set_entity_detail "dkim_records", []


    # If we got a success to the query.
    if dkim_records

      dkim_records.each do |d|
        next unless d["record"] =~ /DKIM/

        # save them 
        _set_entity_detail "dkim_records", dkim_records

        # create a dns record for it
        _create_entity "DnsRecord", d

        # optionally create a domain
        _create_entity "Domain", d["domain"] if _get_option("create_domain")
      end

    end

  end

  def common_selectors(s=nil)

    selectors = [
      { "service"=>"Amazon", "domain" => "amazon.com", "selector"=>"amazonses" },
      { "service"=>"BSD Tools", "domain" => "bluestatedigital.com", "selector"=>"omega" },
      { "service"=>"BSD Tools", "domain" => "bluestatedigital.com", "selector"=>"omicron" },
      { "service"=>"BSD TOOLS (old)", "domain" => "bluestatedigital.com", "selector"=>"campaignDomainKey" },
      { "service"=>"Freshdesk", "domain" => "freshdesk.com", "selector"=>"m1" },
      { "service"=>"Freshdesk", "domain" => "freshdesk.com", "selector"=>"fd" },
      { "service"=>"Freshdesk", "domain" => "freshdesk.com", "selector"=>"fd2" },
      { "service"=>"Freshdesk", "domain" => "freshdesk.com", "selector"=>"fdm" },
      { "service"=>"G Suite", "domain" => "google.com", "selector"=>"google" },
      { "service"=>"Helpscout", "domain" => "helpscout.com", "selector"=>"strong1" },
      { "service"=>"Helpscout", "domain" => "helpscout.com", "selector"=>"strong2" },
      { "service"=>"Mailchimp", "domain" => "mailchimp.com", "selector"=>"k1" },
      { "service"=>"Mailgun", "domain" => "mailgun.com", "selector"=>"mg" },
      { "service"=>"Mandrill", "domain" => "mandrill.com", "selector"=>"mandrill" },
      { "service"=>"MS Office 365", "domain" => "microsoft.com", "selector"=>"selector1" },
      { "service"=>"MS Office 365", "domain" => "microsoft.com", "selector"=>"selector2" },
      { "service"=>"NGP VAN", "domain" => "ngpvan.com", "selector"=>"ngpweb3" },
      { "service"=>"PhpMailer (OLD)", "domain" => nil, "selector"=>"phpmailer" },
      # probably https://yomotherboard.com/how-to-setup-email-server-dkim-keys/
      { "service"=>"PhpMailer (OLD)", "domain" => nil, "selector"=>"mainkey" },
      { "service"=>"PhpMailer", "domain" => nil, "selector"=>"DKIM_identity" },
      { "service"=>"Salesforce", "domain" => "salesforce.com", "selector"=>"selector" },
      { "service"=>"Sendgrid", "domain" => "sendgrid.com", "selector"=>"s1" },
      { "service"=>"Sendgrid", "domain" => "sendgrid.com", "selector"=>"s2" },
      # could be others?  https://www.unlocktheinbox.com/resources/domainkeys/
      { "service"=>"UnlockTheInbox", "domain" => "unlocktheinbox.com", "selector"=>"secure" },
      { "service"=>"Zendesk", "domain" => "zendesk.com", "selector"=>"zendesk1" },
      { "service"=>"Zendesk", "domain" => "zendesk.com", "selector"=>"zendesk2" }
   ]

   # if we were passed a selector, send it back (alone) 
   out = nil
   out = selectors.select{|x| x if x["selector"] == s} if s

  out || selectors 
  end

  def collect_dkim_records(domain)
    _log "Collecting DKIM records"

    dkim_records = []
    common_selectors.each do |cs| 

      lookup_name = "#{cs["selector"]}._domainkey.#{domain}"
      _log "Looking up... #{lookup_name}"

      response = resolve(lookup_name, [Resolv::DNS::Resource::IN::TXT])
      next unless response && !response.empty?

      response.each do |r|
        r["lookup_details"].each do |record|
          selector = lookup_name.gsub("._domainkey.#{domain}","")
          dkim_records << { 
            "name" => lookup_name, 
            "domain" => common_selectors(selector),
            "selector" => selector,
            "record" => record["response_record_data"], 
            "type" => "TXT"
          }
        end
      end

    end
  dkim_records
  end

end
end
end
