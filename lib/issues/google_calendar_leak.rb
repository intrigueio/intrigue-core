module Intrigue
module Issue
class GoogleCalendarLeak < BaseIssue

  def self.generate(instance_details={})
    to_return = {
      added: "2020-01-01",
      name: "google_calendar_leak",
      pretty_name: "Public Google Calendar Enabled!",
      severity: 2,
      status: "confirmed",
      category: "misconfiguration",
      description: "This Google Calendar is set to public. This setting can cause sensitive data leakage.",
      remediation: "Review your event privacy settings to ensure this calendar should be public with specific people",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "remediation", uri: "https://support.google.com/calendar/answer/34580?co=GENIE.Platform%3DDesktop&hl=en" },
      ], 
      task: "vuln/saas_google_calendar_check"
    }.merge!(instance_details)

  to_return
  end

end
end
end
