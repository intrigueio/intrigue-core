module Intrigue
class WebAccountCheckTask < BaseTask

  include Intrigue::Task::Web

  def metadata
    {
      :name => "web_account_check",
      :pretty_name => "Web Account Check",
      :authors => ["jcran"],
      :description => "This task hits major websites, checking for the existence of accounts. Discovered accounts are created.",
      :references => [],
      :allowed_types => ["Person","Organization","Username","WebAccount"],
      :example_entities => [{"type" => "Organization", "attributes" => {"name" => "intrigueio"}}],
      :allowed_options => [
        #{:name => "check_tags", :type => "String", :regex => "alpha_numeric_list", :default => "person,organization" }
      ],
      :created_types => ["WebAccount"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    account_name = _get_entity_attribute "name"
    #tags = _get_options "check_tags"

    account_list_data = File.open("data/web_accounts_list.json").read
    account_list = JSON.parse(account_list_data)

    account_list["sites"].each do |site|

      # craft the uri with our entity's properties
      account_uri = site["check_uri"].gsub("{account}",account_name)
      pretty_uri = site["pretty_uri"].gsub("{account}",account_name) if site["pretty_uri"] 

      # Skip if the site tags don't match our type
      unless site["allowed_types"].include? @entity.type
        @task_log.log "Skipping #{account_uri}, doesn't match our type"
        next
      end

      # Otherwise, go get it
      @task_log.log "Checking #{account_uri}"
      body = http_get_body(account_uri)
      next unless body

      # Check for each string that may indicate we found the account
      account_existence_strings = site["account_existence_strings"]
      account_existence_strings.each do |check_string|
        if body.include? check_string
          _create_entity "WebAccount", {
              "name" => "#{account_name}",
              "domain" => "#{site["name"]}",
              "username" => "#{account_name}",
              "uri" => "#{pretty_uri || account_uri}"
             }
          next
        end
      end
    end

  end # run()

end # ProfileSearch
end
