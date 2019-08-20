module Intrigue
module Task
class UriWellKnownGatherAndParse < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_well_known_gather_and_parse",
      :pretty_name => "URI Gather Well-Known Files (RFC5785)",
      :authors => ["mosesrenegade"],
      :description => "The /.well-known/ directory is defined in RFC5785. Many products" + 
        " have started to use .well-known as the directory can be used to support protocol" +  
        " descriptions. You will find acme-challenge directories for LetsEncrypt" + 
        " pki-validation for several 3rd party PKI's, keybase, assetlinks.json and" +
        " other technologies which may or may live within RFC Spec. See refs for more detail",      
      :references => [
        "https://tools.ietf.org/html/rfc5785",
        "https://www.iana.org/assignments/well-known-uris/well-known-uris.xhtml",
        "https://en.wikipedia.org/wiki/List_of_/.well-known/_services_offered_by_webservers"
      ],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "threads", regex: "integer", :default => 1 },
        {:name => "create_url", regex: "boolean", :default => true },
        {:name => "create_issue", regex: "boolean", :default => false }
      ],
      :created_types => ["Uri"]
    }
  end

  def run
    super

    base_uri = _get_entity_name

    opt_threads = _get_option("threads").to_i
    opt_create_url = _get_option("create_url")
    opt_create_issue = _get_option("create_issue")

    well_known_uri_list = [
      # Phase 1, make this actually find the files, if it does, phase 2 is to open each one of these and get more data.
      { path: "/.well-known/assetlinks.json", severity: 4, body_regex: /android_app/, status: "confirmed" },
      { path: "/.well-known/weebly-verify", severity: 4, body_regex: /<h1>Index Of/, status: "confirmed" },
      { path: "/.well-known/pki-verification", severity: 4, body_regex: /<h1>Index Of/, status: "confirmed" },
      { path: "/.well-known/acme-challenge", severity: 4, body_regex: /<h1>Index Of/, status: "confirmed" },
      { path: "/.well-known/keybase.txt", severity: 4, body_regex: /I hereby claim:/, status: "confirmed" }
    ]

    # make the requests 
    work_q = Queue.new
    well_known_uri_list.each { |x| work_q.push x }
    make_http_requests_from_queue(base_uri, work_q, opt_threads, opt_create_url, opt_create_issue)

  end # end run method

end
end
end



