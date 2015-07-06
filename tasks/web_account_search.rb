class WebAccountSearchTask < BaseTask

  include Task::Web

  def metadata
    { :version => "1.0",
      :name => "web_account_search",
      :pretty_name => "Web Account Search",
      :authors => ["jcran"],
      :description => "This task searches for web accounts by username. Discovered accounts are created.",
      :references => [],
      :allowed_types => ["Username","WebAccount"],
      :example_entities => [{:type => "Username", :attributes => {:name => "jcran"}}],
      :allowed_options => [],
      :created_types => ["WebAccount"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    username = _get_entity_attribute "name"

    account_list_data = File.open("data/web_accounts_list.json").read
    account_list = JSON.parse(account_list_data)

    account_list["sites"].each do |site|

      account_uri = site["check_uri"].gsub("{account}",username)

      body = http_get_body(account_uri)
      next unless body

      #
      # Check for each string that may indicate we didn't find the account
      #
      account_existence_strings = site["account_existence_strings"]
      account_existence_strings.each do |string|
        if body.include? string
          _create_entity "WebAccount", { :name => "#{username}",
                                         :domain => "#{site["name"]}",
                                         :username => "#{username}",
                                         :uri => "#{account_uri}"
                                       }
        end
      end
    end

  end # run()

end # ProfileSearch
