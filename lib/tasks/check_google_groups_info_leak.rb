module Intrigue
module Task
class CheckGoogleGroupsInfoLeak < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "check_google_groups_info_leak",
      :pretty_name => "Check Google Groups Info Leak",
      :authors => ["jcran"],
      :description => "Looks to see if there's a google ",
      :references => [
        "https://blog.redlock.io/google-groups-misconfiguration"
      ],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord"],
      :example_entities => [
        {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [
      ],
      :created_types => ["GoogleGroups"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    domain = _get_entity_name
    uri = "https://groups.google.com/a/#{domain}/forum/#!forumsearch/"
    text = http_get_body uri

    if text =~/gpf_stats.js/
      _log_good "Success!"
      _create_entity "GoogleGroup", {"name" => "#{domain}", "uri" => uri }
    else
      _log_error "Sorry, doesn't seem to be avialable"
    end

  end

end
end
end
