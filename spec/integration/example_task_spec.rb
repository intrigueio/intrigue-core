require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "ExampleTask" do
  include Intrigue::Test::Integration

    ###
    ### example
    ###

    it "runs a default example task and returns the correct result" do

      entity = {
        :type => "DnsRecord",
        :attributes => {
          :name => "test.com"
        }
      }

      # Returns a ruby hash of the task_run
      result = task_start_and_wait("example", entity)

      # Check the result
      expect(result["task_name"]).to match "example"
      expect(result["entity"]["type"]).to match "DnsRecord"
      expect(result["entity"]["attributes"]["name"]).to match "test.com"
      expect(result["entities"].first["type"]).to match "Host"
      expect(result["entities"].first["parent"]["task"]).to match "example: 1.0"
    end

  end
end
