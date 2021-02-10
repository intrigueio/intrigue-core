require_relative 'spec_helper'

describe "Intrigue" do
describe "Issue" do
describe "IssueFactory" do

  it "will parse dns records from web content" do

    # []
    checks_or_tasks = Intrigue::Issue::IssueFactory.checks_for_vendor_product "PHP", "PHP"
    expect(checks_or_tasks).to be_empty

    # ["liferay_portal_cve_2020_7961"]
    checks_or_tasks = Intrigue::Issue::IssueFactory.checks_for_vendor_product "Liferay", "Liferay Portal"
    expect(checks_or_tasks).to include("liferay_portal_cve_2020_7961")

    # => ["uri_brute_focused_content"]
    checks_or_tasks = Intrigue::Issue::IssueFactory.checks_for_vendor_product "Microsoft", "ASP.NET"
    expect(checks_or_tasks).to include("uri_brute_focused_content")
    
  end

end
end
end
