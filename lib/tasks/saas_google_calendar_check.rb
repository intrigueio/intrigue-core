module Intrigue
module Task
class SaasGoogleCalendarCheck < BaseTask


  def self.metadata
    {
      :name => "saas_google_calendar_check",
      :pretty_name => "SaaS Google Calendar Check",
      :authors => ["jcran","jgamblin"],
      :description => "Checks to see if public Google Calendar exists for a given user",
      :references => [
        "https://blogs.ancestry.com/cm/calling-james-smith-10-most-common-first-and-surname-combinations/"
      ],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","EmailAddress"],
      :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "alias_list", :regex=> "alpha_numeric_list", :default =>
          "x,admin,user,test,guest,jsmith,msmith,rsmith,mgarcia,dsmith,mrodriguez,msmith," +
          "mhernandez,mmartinez,jjohnson,james.smith,michael.smith,robert.smith,maria.garcia," +
          "david.smith,maria.rodriguez,mary.smith,maria.hernandez,maria.martinez,james.johnson," +
          "james_smith,michael_smith,robert_smith,maria_garcia,david_smith,maria_rodriguez,mary_smith," +
          "maria_hernandez,maria_martinez,james_johnson"
        }],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # chek if domain type, and build a test list
    if @entity.kind_of? Intrigue::Entity::Domain
      domain = _get_entity_name
      alias_list =  _get_option("alias_list").split(",")
      alias_list.each do |a|
        check_email "#{a}@#{domain}"
      end
    else # just an emali
      email_address = _get_entity_name
      check_email(email_address)
    end
  end


  def check_email(email_address)
    uri = "https://calendar.google.com/calendar/htmlembed?src=#{email_address}"
    response = http_request :get, uri

    if response && response.code == "200"

      service_name = "calendar.google.com"

      ############################################
      ###      Old Issue                      ###
      ###########################################
      # _create_issue({
      #   name: "Public Google Calendar Enabled!",
      #   type: "google_calendar_leak",
      #   severity: 2,
      #   status: "confirmed",
      #   description: "Google Calendar settings are set to public for #{email_address}. This setting can cause sensitive data leakage.",
      #   details: {
      #     "name" => "#{service_name} leak: #{email_address} ",
      #     "uri" => uri,
      #     "email" => "#{email_address}",
      #     "service" => service_name
      #   }
      # })
      
      ############################################
      ###      New Issue                      ###
      ###########################################
      _create_linked_issue({
        detailed_description: "Google Calendar settings are set to public for #{email_address}. This setting can cause sensitive data leakage.",
        details: {
          "name" => "#{service_name} leak: #{email_address} ",
          "uri" => uri,
          "email" => "#{email_address}",
          "service" => service_name
        }
      })

    elsif response && response.code == "404"
     _log "404, doesnt exist or not public..."
    else
      _log "Unknown response..."
      if response
        _log "Code: #{response.code}"
        _log "Code: #{response.body}"
      else
        _log_error "No response!"
      end
    end
  end

end
end
end
