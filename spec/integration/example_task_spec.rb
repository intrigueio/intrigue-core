require_relative '../spec_helper'

describe "Intrigue" do
describe "Task" do
describe "Example" do

    ###
    ### example
    ###

    it "runs a default example task and returns the correct result" do

      entity = {
        "type" => "DnsRecord",
        "details" => {
          "name" => "test.com"
        }
      }

      # Returns a ruby hash of the task_run
      @api = IntrigueApi.new("http://127.0.0.1:7777")
      result = @api.start("Default", "example", entity)

=begin
[1] pry(#<RSpec::ExampleGroups::IntrigueV10Tasks::ExampleTask>)> result
=> {"id"=>"d8e5fb80-4220-4b24-99e9-a5f814733390",
 "name"=>"example",
 "task_name"=>"example",
 "timestamp_start"=>"2015-09-19 23:13:03 UTC",
 "timestamp_end"=>"2015-09-19 23:13:03 UTC",
 "entity_id"=>{"id"=>"b42f5f4d-430b-4a90-8746-9133d34ec93c", "type"=>"IpAddress", "details"=>{"name"=>"test.com"}},
 "options"=>nil,
 "complete"=>true,
 "entity_ids"=>
  [{"id"=>"7c85fa0c-01bc-4875-b8eb-91e09198cf76", "type"=>"IpAddress", "details"=>{"name"=>"47.132.122.212"}},
   {"id"=>"5eaba405-078d-4e3d-8f0d-b70426ae7387", "type"=>"IpAddress", "details"=>{"name"=>"121.141.45.247"}},
   {"id"=>"84917f2e-dcea-45be-9e33-31ad565ad0a7", "type"=>"IpAddress", "details"=>{"name"=>"249.57.82.141"}},
   {"id"=>"1394cf6f-51a5-4816-ad60-083760c9ff5d", "type"=>"IpAddress", "details"=>{"name"=>"115.202.180.248"}},
   {"id"=>"429a238b-acbc-4b92-a3bd-7df65ba4ab1f", "type"=>"IpAddress", "details"=>{"name"=>"210.129.143.208"}},
   {"id"=>"f95a8883-553d-4559-9725-4f5ca0a11a88", "type"=>"IpAddress", "details"=>{"name"=>"114.141.10.89"}},
   {"id"=>"be0a62a5-724a-4243-8b13-9ae16f248a9b", "type"=>"IpAddress", "details"=>{"name"=>"95.225.6.43"}},
   {"id"=>"bce4aa6d-767c-4ce8-b9ff-5de6e6ee8fc3", "type"=>"IpAddress", "details"=>{"name"=>"24.239.45.143"}},
   {"id"=>"f50ce7a8-5a9d-482d-858e-d548b83abfdd", "type"=>"IpAddress", "details"=>{"name"=>"41.89.35.5"}},
   {"id"=>"98e75991-3e7f-4275-8004-6fefd4e2a4ea", "type"=>"IpAddress", "details"=>{"name"=>"214.103.174.118"}}]}
[2] pry(#<RSpec::ExampleGroups::IntrigueV10Tasks::ExampleTask>)> exit
=end

      # Check the result
      expect(result["name"]).to match "example"
      expect(result["entity_id"]["type"]).to match "DnsRecord"
      expect(result["entity_id"]["details"]["name"]).to match "test.com"
      expect(result["entity_ids"].first["type"]).to match "DnsRecord"
    end

  end
end
end