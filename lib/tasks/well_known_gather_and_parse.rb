module Intrigue
module Task
class WellKnownGatherAndParse < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "well_known_gather_and_parse",
      :pretty_name => "Files known to reside within the /.well-known/ directory",
      :authors => ["mosesrenegade"],
      :description => "The /.well-known/ directory is an RFC standard many products" + 
        " have started to use .well-known as its always available to support protocol" +  
        " descriptions. You will find acme-challenge directories for LetsEncrypt" + 
        " pki-validation for several 3rd party PKI's, keybase, assetlinks.json and" +
        " other technologies which may or may live within RFC Spec. See: " +
        " https://www.iana.org/assignments/well-known-uris/well-known-uris.xhtml",      
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "threads", regex: "integer", :default => 1 },
        {:name => "create_url", regex: "boolean", :default => false }
      ],
      :created_types => ["Uri"]
    }
  end

  def run
    super

    base_uri = _get_entity_name

    opt_threads = _get_option("threads") 
    opt_create_url = _get_option("create_url")
    opt_generic_content = _get_option("check_generic_content") 

    well_known_uri_list = [
      # Phase 1, make this actually find the files, if it does, phase 2 is to open each one of these and get more data.
      { path: "/.well-known/assetlinks.json", severity: 3, body_regex: /android_app/, status: "confirmed" },
      { path: "/.well-known/weebly-verify", severity: 3, body_regex: /<h1>Index Of/, status: "confirmed" },
      { path: "/.well-known/pki-verification", severity: 3, body_regex: /<h1>Index Of/, status: "confirmed" },
      { path: "/.well-known/acme-challenge", severity: 3, body_regex: /<h1>Index Of/, status: "confirmed" },
      { path: "/.well-known/keybase.txt", severity: 3, body_regex: /I hereby claim:/, status: "confirmed" }
    ]

    work_q = Queue.new

    well_known_uri_list.each { |x| work_q.push x } if opt_generic_content

    make_http_requests_from_queue(uri, work_q, opt_threads, opt_create_url, false)

  end # end run method

end
end
end



