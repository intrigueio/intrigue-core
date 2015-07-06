require 'twitter'
class TwitterGatherFriends < BaseTask

  def metadata
    { :version => "1.0",
      :name => "twitter_gather_friends",
      :pretty_name => "Twitter Gather Friends",
      :authors => ["jcran"],
      :description => "Gather twitter accounts the provided user is following",
      :references => [],
      :allowed_types => ["WebAccount","String"],
      :example_entities => [
        {:type => "WebAccount", :attributes => {:name => "intrigueio", :domain=>"twitter"}}
      ],
      :allowed_options => [
        {:name => "max_accounts", :type => "Integer", :regex=> "integer", :default => 25 },
      ],
      :created_types => ["WebAccount"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    twitter_account = _get_entity_attribute "name"
    max_accounts = _get_option "max_accounts"

    raise "Twitter API keys required!" unless $intrigue_config["twitter_consumer_key"] && $intrigue_config["twitter_consumer_secret"] && $intrigue_config["twitter_access_token"] && $intrigue_config["twitter_access_token_secret"]

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = $intrigue_config["twitter_consumer_key"]
      config.consumer_secret     = $intrigue_config["twitter_consumer_secret"]
      config.access_token        = $intrigue_config["twitter_access_token"]
      config.access_token_secret = $intrigue_config["twitter_access_token_secret"]
    end

    response = client.friend_ids(twitter_account)

    binding.pry

    begin
      iterate = 0

      @task_log.log "Found: #{response.count} friends"
      @task_log.log "Limiting to #{max_accounts}" if response.count > max_accounts

      response.each do |friend_id|
        iterate += 1
        @task_log.log "Friend: #{friend_id}"
        _create_entity("WebAccount",  :name => "#{friend_id}",
                                      :uri => "https://twitter.com/#{friend_id}",
                                      :domain => "Twitter")
        return if iterate >= max_accounts
      end

    rescue Twitter::Error::TooManyRequests => e
      @task_log.error "Requested too many friends #{e}"
    end

  end

end
