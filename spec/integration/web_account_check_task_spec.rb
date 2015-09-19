require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "WebAccountCheckTask" do

    ###
    ### dns_lookup_reverse
    ###

    it "runs a default web_account_check and returns the correct result" do

      entity = {
        "type" => "Person",
        "attributes" => {
          "name" => "test"
        }
      }

      # Returns a ruby hash of the task_run
      @api = IntrigueApi.new
      result = @api.start("web_account_check", entity)

      # Check the result

    end

  end
end
