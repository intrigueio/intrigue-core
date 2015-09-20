require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "WebAccountCheckTask" do

=begin
    it "checks each site in data/web_accounts_list.json for false positives" do

      entity = {
        "type" => "String",
        "attributes" => {
          "name" => "does-not-exist-#{rand(1000000000000)}"
        }
      }

      @api = IntrigueApi.new
      result = @api.start("web_account_check", entity)

      expect(result["entity_ids"].count).to be 0
    end
=end

    it "checks each site in data/web_accounts_list.json for false negatives" do

      @api = IntrigueApi.new

      account_list_data = File.open("data/web_accounts_list.json").read
      account_list = JSON.parse(account_list_data)

      account_list["sites"].each do |site|

        # Create an entity that can be saved
        entity = {
          "type" => "String",
          "attributes" => {
            "name" => "#{site["known_accounts"].first}"
          }
        }

        result = @api.start("web_account_check", entity, [{"name" => "specific_sites", "value" => "#{site["name"]}"}])

        #expect(result["entity_ids"].count).to eq 1

        if result["entity_ids"].count < 1
          puts "Found #{result["entity_ids"].count} accounts. #{site["check_uri"].gsub("{account}", site["known_accounts"].first)}"
        end

      end
    end
  end
end
