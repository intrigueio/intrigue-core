module Intrigue
  module Issue
  class JiraManageFiltersInfoLeak < BaseIssue
  
    def self.generate(instance_details={})
  
      to_return = {
        added: "2020-01-01",
        name: "jira_managefilters_info_leak",
        pretty_name: "Jira (manageFilters.jspa) Info Leak",
        category: "misconfiguration",
        severity: 3,
        status: "confirmed",
        description: "We detected a jira instance with a configuration that allows the issue filters to be seen by anonymous users.",
        remediation:  "Check each specific filter / dashboard shared with everyone by going to JIRA Administration > System > Shared Filters / Shared Dashboards. Look for settings specified as “Shared with the public” or “Shared with all users” (if you are using old version of JIRA server).",
        affected_software: [
          { :vendor => "Atlassian", :product => "Jira" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://medium.flatstack.com/misconfig-in-jira-for-accessing-internal-information-of-any-company-2f54827a1cc5" },
          { type: "remeediation", uri: "https://medium.flatstack.com/misconfig-in-jira-for-accessing-internal-information-of-any-company-2f54827a1cc5" },
          { type: "remediation", uri: "https://confluence.atlassian.com/adminjiraserver/managing-shared-filters-938847876.html" }
        ], 
        check: "uri_brute_focused_content"
      }.merge(instance_details)
      
    to_return
    end
  
  end
  end
  end