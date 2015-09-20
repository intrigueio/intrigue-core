require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "WebAccountCheckTask" do

    ###
    ### dns_lookup_reverse
    ###

    it "runs with a non-existent account and returns no results" do

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

    it "runs with account that exists and returns every result" do

      entity = {
        "type" => "String",
        "attributes" => {
          "name" => "test"
        }
      }

      account_list_data = File.open("data/web_accounts_list.json").read
      account_list = JSON.parse(account_list_data)

      @api = IntrigueApi.new
      result = @api.start("web_account_check", entity)

      pp result.inspect

      #expect(result["entity_ids"].count).to eq(account_list.count)
    end


  end
end
