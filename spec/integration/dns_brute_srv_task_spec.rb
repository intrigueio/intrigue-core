require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "DnsSrvBruteTask" do

    ###
    ### dns_brute_srv
    ###

    it "runs a default dns_brute_srv and returns the correct result" do

      entity = {"type" => "DnsRecord", "details" => {"name" => "rapid7.com"}}

      # Returns a ruby hash of the task_run
      @api = IntrigueApi.new
      result = @api.start("dns_brute_srv", entity)

      # Check the result
      #expect(result["entities"]).to
    end

  end
end
