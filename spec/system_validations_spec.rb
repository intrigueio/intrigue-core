require_relative 'spec_helper'

describe "Intrigue" do
describe "Core" do
describe "System" do
describe "Validations" do

  include Intrigue::Core::System::Validations

  it "has a phone_number_regex that will validate a phone number" do

    expect("444.444.1232").to match phone_number_regex
    expect("444.444as1232").not_to match phone_number_regex

  end

end
end
end
end