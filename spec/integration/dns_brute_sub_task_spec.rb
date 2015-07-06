require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "DnsSubBruteTask" do
    include Intrigue::Test::Integration


    ###
    ### This test runs a dns_brute_sub with the brute_list option, allowing us to check
    ### option processing at the same time.
    ###
    it "runs a dns_brute_sub with a brute_list option and returns the correct result" do

      entity = {:type => "DnsRecord", :attributes => {:name => "intrigue.io"}}
      options = [{:name => "brute_list", :value => "test,test2,download"}]
      # Returns a ruby hash of the task_run
      result = task_start_and_wait("dns_brute_sub", entity, options )

      #pp result

      #54.165.20.201
      correct = [{"type"=>"DnsRecord",
       "attributes"=>{"name"=>"download.intrigue.io"},
       "parent"=>
        {"task"=>"dns_brute_sub: 1.0",
         "entity"=>{"type"=>"DnsRecord", "attributes"=>{"name"=>"intrigue.io"}}}},
      {"type"=>"Host",
       "attributes"=>{"name"=>"54.165.20.201"},
       "parent"=>
        {"task"=>"dns_brute_sub: 1.0",
         "entity"=>
          {"type"=>"DnsRecord", "attributes"=>{"name"=>"intrigue.io"}}}}]

      # Check the result
      expect(result["entities"]).to match correct
    end

    ###
    ### Default settings. XXX -- this needs a test domain. tests flapping
    ###
    it "runs a default dns_brute_sub and returns the correct result" do

      entity = {:type => "DnsRecord", :attributes => {:name => "spec.intrigue.io"}}

      # Returns a ruby hash of the task_run
      result = task_start_and_wait("dns_brute_sub", entity)

      correct = [{"type"=>"DnsRecord",
                    "attributes"=>{"name"=>"help.spec.intrigue.io"},
                    "parent"=>
                     {"task"=>"dns_brute_sub: 1.0",
                      "entity"=>
                       {"type"=>"DnsRecord", "attributes"=>{"name"=>"spec.intrigue.io"}}}},
                   {"type"=>"Host",
                    "attributes"=>{"name"=>"1.1.1.1"},
                    "parent"=>
                     {"task"=>"dns_brute_sub: 1.0",
                      "entity"=>
                       {"type"=>"DnsRecord", "attributes"=>{"name"=>"spec.intrigue.io"}}}}]

      # Check the result
      expect(result["entities"]).to match correct
    end

  end
end
