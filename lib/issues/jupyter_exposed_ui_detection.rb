module Intrigue
  module Issue
  class JupyterExposedUiDetection < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "jupyter_exposed_ui_detection",
        pretty_name: "Jupyter Exposed UI Detection",
        severity: 4,
        category: "application",
        status: "confirmed",
        description:  "This detector checks whether a unauthenticated Jupyter Notebook is exposed. Jupyter" + 
                      " allows by design to run arbitrary code on the host machine. Having it exposed puts" + 
                      " the hosting VM at risk of RCE.",
        remediation: "Put the Jupyter notebook behind authentication.",
        affected_software: [ { :vendor => "Jupyter", :product => "Notebook" } ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://jupyter-notebook.readthedocs.io/en/stable/security.html" },
          { type: "source", uri: "https://github.com/google/tsunami-security-scanner-plugins/blob/master/google/detectors/exposedui/jupyter/src/main/java/com/google/tsunami/plugins/detectors/exposedui/jupyter/JupyterExposedUiDetector.java"}
        ], 
        check: "uri_brute_focused_content"
      }.merge!(instance_details)
    end
  
  end
  end
  end