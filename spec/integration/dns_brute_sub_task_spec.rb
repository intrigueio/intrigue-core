require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "DnsSubBruteTask" do

    ###
    ### This test runs a dns_brute_sub with the brute_list option, allowing us to check
    ### option processing at the same time.
    ###
    it "runs a dns_brute_sub with a brute_list option and returns the correct result" do

      entity = {"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}
      options = [{:name => "brute_list", :value => "test,test2,download"}]

      # Returns a ruby hash of the task_run
      @api = IntrigueApi.new
      result = @api.start("dns_brute_sub", entity)

      # Check the result
      #expect(result["entities"]).to match correct
    end

    ###
    ### Default settings. XXX -- this needs a test domain. tests flapping
    ###
    it "runs a default dns_brute_sub and returns the correct result" do

      entity = {:type => "DnsRecord", :attributes => {:name => "spec.intrigue.io"}}

      # Returns a ruby hash of the task_run
      @api = IntrigueApi.new
      result = @api.start("dns_brute_sub", entity)

      # Check the result
      #expect(result["entities"]).to match correct
    end

  end
end
