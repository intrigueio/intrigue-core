module Intrigue
module Task
class EmailBruteGmailGlxu < BaseTask

  def self.metadata
    {
      :name => "email_brute_gmail_glxu",
      :pretty_name => "Email Brute Gmail GLXU",
      :authors => ["jcran", "x0rz"],
      :description => "This task uses an enumeration bug in the mail/glxu endpoint on gmail to check account existence.",
      :references => [
        "https://blog.0day.rocks/abusing-gmail-to-get-previously-unlisted-e-mail-addresses-41544b62b2"
      ],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "alias_list", :regex => "alpha_numeric_list", :default => "admin,john,mike,sharon,michelle,bob,jsmith,test,guest,x" },
      ],
      :created_types => ["EmailAddress"]
    }
  end

  def run
    super

    domain = _get_entity_name
    alias_list = _get_option "alias_list"

    alias_list.each do |a|
      email_address = "#{a}@#{domain}"
      req = http_request :get, "https://mail.google.com/mail/gxlu?email=#{email_address}"

      # if valid, create the email
      if req["set-cookie"]
        _log_good "Found: #{email_address}"
        _create_entity "EmailAddress", "name" => email_address
      else 
        _log "Not Found: #{email_address}"
      end

    end

  end

end
end
end
