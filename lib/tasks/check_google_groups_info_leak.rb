module Intrigue
module Task
class CheckGoogleGroupsInfoLeak < BaseTask


  def self.metadata
    {
      :name => "check_google_groups_info_leak",
      :pretty_name => "Check Google Group Info Leak",
      :authors => ["jcran","jgamblin"],
      :description => "Looks to see if there's a google group listing for a given domain",
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
        {:name => "notify_slackbot", :type => "Boolean", :regex => "boolean", :default => false }
      ],
      :created_types => ["GoogleGroup"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    domain = _get_entity_name

    uri = "https://groups.google.com/a/#{domain}/forum/#!search/a"
    text = http_get_body uri

    if text =~ /gpf_stats.js/

      # capture a screenshot and save it as a detail
      page = "https://groups.google.com/a/#{domain}/forum/#!search/a"
      session = create_browser_session(page)
      base64_screenshot_data_search = capture_screenshot(session)

      page = "https://groups.google.com/a/#{domain}/forum/#!forumsearch/"
      session = create_browser_session(page)
      base64_screenshot_data_listing = capture_screenshot(session)

      page = "https://groups.google.com/a/#{domain}/forum/#!search/password"
      session = create_browser_session(page)
      base64_screenshot_data_search_password = capture_screenshot(session)

      page = "https://groups.google.com/a/#{domain}/forum/#!search/breach"
      session = create_browser_session(page)
      base64_screenshot_data_search_breach = capture_screenshot(session)

      page = "https://groups.google.com/a/#{domain}/forum/#!search/payment"
      session = create_browser_session(page)
      base64_screenshot_data_search_payment = capture_screenshot(session)

      page = "https://groups.google.com/a/#{domain}/forum/#!search/invoice"
      session = create_browser_session(page)
      base64_screenshot_data_search_invoice = capture_screenshot(session)

      _create_entity "GoogleGroup", {
        "name" => domain,
        "uri" => uri,
        "hidden_screenshot_listing" => base64_screenshot_data_listing,
        "hidden_screenshot_search" => base64_screenshot_data_search,
        "hidden_screenshot_search_password" => base64_screenshot_data_search_password,
        "hidden_screenshot_search_breach" => base64_screenshot_data_search_breach,
        "hidden_screenshot_search_payment" => base64_screenshot_data_search_payment,
        "hidden_screenshot_search_invoice" => base64_screenshot_data_search_invoice
      }

      # this should be a "Finding" or some sort of success event ?
      _call_handler("slackbot") if _get_option("notify_slackbot")

    elsif text =~ /This group is on a private domain/
      # good
      # CHECK //div[@class='gwt-Label'][contains(text(),'No results found')]
      _log_good "This domain does not appear to be vulnerable."
    else
      _log_error "Unknown..."
    end

  end

end
end
end
