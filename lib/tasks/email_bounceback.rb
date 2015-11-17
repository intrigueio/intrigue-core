require 'gmail'

module Intrigue
class EmailBouncebackTest < BaseTask

  def metadata
    {
      :name => "email_bounceback",
      :pretty_name => "Email Bounceback",
      :authors => ["jcran"],
      :description => "This task checks a domain for an email bounceback.",
      :references => [],
      :allowed_types => ["DnsRecord"],
      :example_entities => [
        {"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    domain = _get_entity_attribute "name"

    username = _get_global_config("gmail_account_credentials").split(":").first
    password = _get_global_config("gmail_account_credentials").split(":").last
    gmail = Gmail.connect(username, password)

    email_address = "#{rand(100000000)}@#{domain}"

    @task_result.logger.log "Sending email to #{email_address}"
    email = gmail.compose do
      to email_address
      subject "Having fun in the sun!"
      text_part do
        body "Come join us!"
      end
    end
    email.deliver!

    @task_result.logger.log "Waiting 15 seconds for the bounceback... "
    @task_result.save
    sleep 15

    gmail.inbox.emails(gm: "#{email_address}").each do |email|

      # Parse each email address for servers
      email.message.received.each {|server|
        @task_result.logger.log "Processing #{server}"

        # Get the server name from the string
        server_name = server.to_s.split(' ')[1]

        # Create the apropriate entities
        ("#{server_name}".gsub(".","").alpha? ? entity_type = "DnsRecord" : entity_type = "IpAddress" )
        _create_entity entity_type, {
          "name" => server_name,
          "server" => "#{server}",
          "email" => "#{email_address}"
        }
      }

      email.delete!
    end

  end

end
end
