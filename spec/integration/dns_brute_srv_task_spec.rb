require_relative '../spec_helper'

describe "Intrigue v1.0 Tasks" do
  describe "DnsSrvBruteTask" do
    include Intrigue::Test::Integration

    ###
    ### dns_brute_srv
    ###

    it "runs a default dns_brute_srv and returns the correct result" do

      entity = {:type => "DnsRecord", :attributes => {:name => "rapid7.com"}}

      # Returns a ruby hash of the task_run
      result = task_start_and_wait("dns_brute_srv", entity)

      correct = [
        {"type"=>"DnsRecord",
          "attributes"=>{"name"=>"_sip._tls.rapid7.com"},
          "parent"=>
            {"task"=>"dns_brute_srv: 1.0",
              "entity"=>{"type"=>"DnsRecord", "attributes"=>{"name"=>"rapid7.com"}}}},
        {"type"=>"Host",
          "attributes"=>{"name"=>"sipdir.online.lync.com"},
          "parent"=>
            {"task"=>"dns_brute_srv: 1.0",
              "entity"=>{"type"=>"DnsRecord", "attributes"=>{"name"=>"rapid7.com"}}}},
        {"type"=>"NetSvc",
          "attributes"=>
          {"name"=>"sipdir.online.lync.com:443/tcp",
            "proto"=>"tcp",
            "port"=>443,
            "ip_address"=>"sipdir.online.lync.com"},
            "parent"=>
              {"task"=>"dns_brute_srv: 1.0",
                "entity"=>{"type"=>"DnsRecord", "attributes"=>{"name"=>"rapid7.com"}}}},
        {"type"=>"DnsRecord",
          "attributes"=>{"name"=>"_sipfederationtls._tcp.rapid7.com"},
          "parent"=>
          {"task"=>"dns_brute_srv: 1.0",
            "entity"=>{"type"=>"DnsRecord", "attributes"=>{"name"=>"rapid7.com"}}}},
            {"type"=>"Host",
              "attributes"=>{"name"=>"sipfed.online.lync.com"},
              "parent"=>
                {"task"=>"dns_brute_srv: 1.0",
                  "entity"=>{"type"=>"DnsRecord", "attributes"=>{"name"=>"rapid7.com"}}}},
        {"type"=>"NetSvc",
          "attributes"=>
          {"name"=>"sipfed.online.lync.com:5061/tcp",
            "proto"=>"tcp",
            "port"=>5061,
            "ip_address"=>"sipfed.online.lync.com"},
            "parent"=>
              {"task"=>"dns_brute_srv: 1.0",
                "entity"=>{"type"=>"DnsRecord", "attributes"=>{"name"=>"rapid7.com"}}}}]

      # Check the result
      expect(result["entities"]).to match correct
    end

  end
end
