require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "WebAccountCheckTask" do


    it "checks each site in data/web_accounts_list.json for false negatives" do

      @api = IntrigueApi.new("http://127.0.0.1:7777/v1")

      account_list_data = File.open("data/web_accounts_list.json").read
      account_list = JSON.parse(account_list_data)

      account_list["sites"].each do |site|
        puts "Checking site: #{site["name"]}"

        # Create an entity that can be saved
        entity = {
          "type" => "String",
          "details" => {
            "name" => "#{site["known_accounts"].first}"
          }
        }

        result = @api.start("Default", "web_account_check", entity, [{"name" => "specific_sites", "value" => "#{site["name"]}"}])

        if result["entity_ids"].count < 1
          puts "Found #{result["entity_ids"].count} accounts. #{site["check_uri"].gsub("{account}", site["known_accounts"].first)}. FAIL."
        end

        # Fail if we don't get a result
        expect(result["entity_ids"].count).to eq 1
      end

    end

    it "checks each site in data/web_accounts_list.json for false positives" do

      entity = {
        "type" => "String",
        "details" => {
          "name" => "does-not-exist-#{rand(1000000000000)}"
        }
      }

      @api = IntrigueApi.new("http://127.0.0.1:7777/v1")
      puts "Checking all sites for false positives"
      result = @api.start("Default", "web_account_check", entity)

      # We should never get a result
      expect(result["entity_ids"].count).to be 0
    end

  end
end
