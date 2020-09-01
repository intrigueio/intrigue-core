require_relative 'spec_helper'

describe "Intrigue" do
describe "System" do

  it "should match a system exception" do

    result = standard_no_traverse?("hubspot.com", "Domain", [])
    puts result

    expect(result).to be_a_kind_of(Regexp)
  end

end
end
