require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "WebAccountCheckTask" do

    ###
    ### dns_lookup_reverse
    ###

    it "runs a default web_account_check and returns the correct result" do

      entity = {
        "type" => "String",
        "attributes" => {
          "name" => "does-not-exist-#{rand(1000000000000)}"
        }
      }

      # Returns a ruby hash of the task_run
      @api = IntrigueApi.new
      result = @api.start("web_account_check", entity)
      expect(result["entity_ids"].count).to be 0


      # Check the result

    end

  end
end
