
module Intrigue
module Issue
  class KubernetesDefaultPathExposed < BaseIssue
    def self.generate(instance_details={})
    {
      added: "2021-04-04",
      name: "kubernetes_sensitive_content_exposed",
      pretty_name: "Kubernetes Sensitive Content Exposed",
      severity: 2,
      category: "misconfiguration",
      status: "confirmed",
      description: "A Kubernetes instance is exposing sensitive content at a publicly available path.",
      affected_software: [
        { :vendor => "Kubernetes", :product => "Kubernetes" }
      ],
      references: [
        { type: "description", uri: "http://blog.madhukaraphatak.com/understanding-k8s-api-part-2/" },
        { type: "description", uri: "https://github.com/aquasecurity/kube-hunter" },
        { type: "description", uri: "https://gist.github.com/oomichi/bc0044624443b4b596bdb4c83dd4ad4b"}, 
        { type: "description", uri: "https://github.com/random-robbie/bruteforce-lists/blob/master/k8s.txt"}
      ],
      authors: ["jcran"]
    }.merge!(instance_details)
    end
  end
end

module Task
  class KubernetesDefaultPathExposed < BaseCheck

  def self.check_metadata
    {
      allowed_types: ["Uri"]
    }
  end

  # return truthy value to create an issue
  def check

    # run a nuclei
    uri = _get_entity_name


    known_paths = <<-eos
/api
/api/v1
/api/v1/namespaces
/api/v1/nodes
/api/v1/pods
/apis
/apis/admissionregistration.k8s.io/v1beta1
/apis/apiextensions.k8s.io/v1beta1
/apis/apiregistration.k8s.io/v1beta1
/apis/apps/v1
/apis/apps/v1beta1
/apis/apps/v1beta2
/apis/authentication.k8s.io/v1
/apis/authentication.k8s.io/v1beta1
/apis/authorization.k8s.io/v1
/apis/authorization.k8s.io/v1beta1
/apis/autoscaling/v1
/apis/autoscaling/v2beta1
/apis/batch/v1
/apis/batch/v1beta1
/apis/certificates.k8s.io/v1beta1
/apis/events.k8s.io/v1beta1
/apis/extensions/v1beta1
/apis/extensions/v1beta1/podsecuritypolicies
/apis/networking.k8s.io/v1
/apis/policy/v1beta1
/apis/rbac.authorization.k8s.io/v1
/apis/rbac.authorization.k8s.io/v1beta1
/apis/storage.k8s.io/v1
/apis/storage.k8s.io/v1beta1
/version
/api/v1/namespaces/default/pods/
/api/v1/namespaces/default/pods/test/status
/api/v1/namespaces/default/secrets/
/apis/extensions/v1beta1/namespaces/default/deployments
/apis/extensions/v1beta1/namespaces/default/daemonsets
ca-key.pem
token_auth.csv
ca.pem
config.seen
cloud-provider.yaml
apiserver.pem
10-flannel.conf
config.source
audit.log
config.hash
apiserver-key.pem
cni-conf.json
kube-proxy.log
apiserver-aggregator-ca.cert
apiserver-aggregator.cert
server.cert
ca.key
etcd-events.log
kube-scheduler.log
node-role.kubernetes.io
kube-apiserver.log
basic_auth.csv
dns.alpha.kubernetes.io
apiserver-aggregator.key
etcd.log
known_tokens.csv
kube-controller-manager.log
ca.crt
server.key
run.sh
etcd-apiserver-client.key
etcd-ca.crt
admission_controller_config.yaml
serviceaccount.crt
apiserver-client.crt
ca-certificates.crt
apiserver.crt
kube-addons.sh
gce.conf
pv-recycler-template.yaml
etcd-apiserver-client.crt
proxy_client.crt
apiserver.key
etcd-apiserver-server.crt
etcd-apiserver-ca.crt
etcd-apiserver-server.key
serviceaccount.key
etcd-peer.key
aggr_ca.crt
migrate-if-needed.sh
apiserver-client.key
proxy_client.key
etcd-peer.crt
kube-addon-manager.log
kube-apiserver-audit.log
glbc.log
eos



    # default value for the check response
    out = false

    # first test that we can get something
    contents = http_get_body "#{uri}"
    _log_error "failing, unable to get a response" unless contents

    # get a missing page, and sha the dom
    benign_contents = http_get_body "#{uri}/api/v1/namespaces/default/pods/#{rand(10000000000)}.aspx"
    benign_content_sha = Digest::SHA1.hexdigest(html_dom_to_string(benign_contents))

    # check all paths for a non-error response
    known_paths.split("\n").each do |k8path|
      _log "Getting: #{k8path}"

      full_path = "#{uri}#{k8path}"

      # get the body and do the same thing as above
      contents = http_get_body full_path
      our_sha = Digest::SHA1.hexdigest(html_dom_to_string(contents))

      # now check them
      default_response = /default backend \- 404/
      if our_sha != benign_content_sha && !contents =~ default_response
        heuristic_match = true
        _log "Odd contents for #{full_path}!, flagging"
        out = construct_positive_match(full_path, contents, benign_contents)
      else
        _log "Got same content for missing page, probably okay"
      end

    end

  out
  end

  def construct_positive_match(full_path, contents, benign_contents)
    out = {
      url: full_path,
      contents: contents,
      benign_contents: benign_contents,
      details: "Check diff of contents vs benign contents" }
  end

end
end

end