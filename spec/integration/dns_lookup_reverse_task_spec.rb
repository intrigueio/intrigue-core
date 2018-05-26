require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "DnsLookupReverseTask" do

    ###
    ### dns_lookup_reverse
    ###

    it "runs a default dns_lookup_reverse and returns the correct result" do

      entity = {
        "type" => "IpAddress",
        "details" => {
          "name" => "8.8.8.8"
        }
      }

      # Returns a ruby hash of the task_run
      @api = IntrigueApi.new("http://127.0.0.1:7777")
      result = @api.start("Default", "dns_lookup_reverse", entity)

      # Check the result
      expect(result["entity_ids"].first["details"]["name"]).to match /google-public-dns-a.google.com/
    end

  end
end
