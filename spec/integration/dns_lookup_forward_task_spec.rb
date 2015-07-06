require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "DnsLookupForwardTask" do
  include Intrigue::Test::Integration

    ###
    ### dns_lookup_forward
    ###

    it "runs a default dns_lookup_forward task and returns the correct result" do

      entity = {
        :type => "DnsRecord",
        :attributes => {
          :name => "intrigue.io"
        }
      }

      # Returns a ruby hash of the task_run
      result = task_start_and_wait("dns_lookup_forward", entity)

      # Check the result
      expect(result["task_name"]).to match "dns_lookup_forward"
      expect(result["entity"]["type"]).to match "DnsRecord"
      expect(result["entities"].first["type"]).to match "Host"
      expect(result["entities"].first["attributes"]["name"]).to match /192.0.78.*/
    end

  end
end
