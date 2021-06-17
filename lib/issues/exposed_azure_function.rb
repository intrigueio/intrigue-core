module Intrigue
  module Issue
  class ExposedAzureFunction < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2021-06-16",
        name: "exposed_azure_function",
        pretty_name: "Exposed Azure Function",
        severity: 3,
        category: "misconfiguration",
        status: "confirmed",
        description: "A cloud function was discovered exposed to the Internet.",
        remediation: "Prevent access to this cloud function if it should not be exposed.",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          {
            type: "description",
            url: "https://docs.microsoft.com/en-us/answers/questions/258839/how-to-prevent-34your-functions-30-app-is-up-and-r.html"
          },
          {
            type: "remediation",
            url: "https://docs.microsoft.com/en-us/azure/azure-functions/functions-app-settings#azurewebjobsdisablehomepage"
          }
        ],
        # task: handled in ident
      }.merge!(instance_details)
    end

  end
  end
  end