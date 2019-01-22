require_relative 'spec_helper'

describe "Intrigue" do
describe "Task" do
describe "Whois" do

  include Intrigue::Task::Whois

  it "can query an ip in RDAP and receive a positive response" do
    response = rdap_ip_lookup "1.1.1.1"
    expect(response.has_key? "name").to eq(true)
    expect(response["start_address"]).to eq("1.1.1.0")
    expect(response["cidr"]).to eq("24")
  end

  it "can query an ip in RDAP and receive a positive response" do
    response = rdap_ip_lookup "189.44.225.205"
    puts "RESPONSE: #{response}"
    expect(response.has_key? "name").to eq(true)
    expect(response["start_address"]).to eq("189.44.225.200")
    expect(response["cidr"]).to eq("29")
  end

end
end
end
