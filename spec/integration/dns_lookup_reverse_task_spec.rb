require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "DnsLookupReverseTask" do
    include Intrigue::Test::Integration

    ###
    ### dns_lookup_reverse
    ###

    it "runs a default dns_lookup_reverse and returns the correct result" do

      entity = {
        :type => "Host",
        :attributes => {
          :name => "8.8.8.8"
        }
      }

      # Returns a ruby hash of the task_run
      result = task_start_and_wait("dns_lookup_reverse", entity)

      # Check the result
      expect(result["entities"].first["attributes"]["name"]).to match /google-public-dns-a.google.com/
    end

  end
end
