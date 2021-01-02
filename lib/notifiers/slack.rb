module Intrigue
module Notifier
  class Slack < Intrigue::Notifier::Base

    include Intrigue::Task::Web
    include Intrigue

    def self.metadata
      { :type => "slack" }
    end

    def initialize(config_hash)
      #puts "Creating new slack notifier with config: #{config_hash}"

      # Assumes amazon...
      if config_hash["system_base_uri"] == "AMAZON"
        # use the standard endpoint to grab info 
        @system_base_uri = "https://#{hostname}:7777"
      else # use as is
        @system_base_uri = config_hash["system_base_uri"] || "https://#{hostname}:7777"
      end

      @hook_url = config_hash["slack_hook_url"]
    end

    def notify(message, result=nil)

      result_url = "#{@system_base_uri}"
      result_url += "/#{result.project.name}/results/#{result.id}" if result

      constructed_message = "#{message}\nMore details at: #{result_url}"

      begin

        response = RestClient.post @hook_url,{
          :text => constructed_message
        }.to_json,{content_type: :json, accept: :json}
    
      rescue RestClient::TooManyRequests => e
        puts "ERROR! #{e}"
      rescue RestClient::BadRequest => e
        puts "ERROR! #{e}"
      rescue SocketError => e
        puts "ERROR! #{e}"    
      rescue Errno::EADDRNOTAVAIL => e
        puts "ERROR! #{e}"
      rescue RestClient::Exceptions::OpenTimeout => e
        puts "ERROR! Timed out attempting to notify: #{e}"
      end

    end
  end

end
end
