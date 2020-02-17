module Intrigue
module Issue
class GoogleCalendarLeakr< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "google_calendar_leak",
      pretty_name: "Public Google Calendar Enabled!",
      severity: 2,
      status: "confirmed",
      category: "application",
      description: "Google Calendar settings are set to public. This setting can cause sensitive data leakage.",
      remediation: "Change your event privacy settings to only share with specific people",
      affected: [],
      references: ["https://support.google.com/calendar/answer/34580?co=GENIE.Platform%3DDesktop&hl=en" # types: description, remediation, detection_rule, exploit, threat_intel
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
