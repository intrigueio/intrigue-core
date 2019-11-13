module Intrigue
module Task
class SaasGoogleGroupsCheck < BaseTask


  def self.metadata
    {
      :name => "saas_google_groups_check",
      :pretty_name => "SaaS Google Groups Check",
      :authors => ["jcran","jgamblin"],
      :description => "Checks to see if public Google Groups exist for a given domain",
      :references => [
        "https://blog.redlock.io/google-groups-misconfiguration",
        "https://www.kennasecurity.com/widespread-google-groups-misconfiguration-exposes-sensitive-information/",
        "https://krebsonsecurity.com/2018/06/is-your-google-groups-leaking-data/"
      ],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","DnsRecord"],
      :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => ["WebAccount"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    domain = _get_entity_name

    uri = "https://groups.google.com/a/#{domain}/forum/#!search/a"
    text = http_get_body uri

    if text =~ /gpf_stats.js/

      _log_good "Success! Domain is configured and public."
      service_name = "groups.google.com"

      _create_issue({
        name: "Public Google Groups Enabled!",
        type: "google_groups_leak",
        severity: 3,
        status: "confirmed",
        description: "Public Google Groups settings enabled on #{domain} can cause sensitive data leakage.",
        details: {
          "name" => "#{service_name} leak: #{domain}",
          "uri" => uri,
          "username" => "#{domain}",
          "service" => service_name
        }
      })

    elsif text =~ /This group is on a private domain/
      # good
      _log "This domain is configured in G Suite, but is not public."
    else
      _log "Unknown..."
    end

  end

end
end
end
