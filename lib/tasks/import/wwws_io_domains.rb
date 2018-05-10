module Intrigue
module Task
class ImportWwwsIoDomains < BaseTask

  include Intrigue::Task::Generic
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "import/wwws_io_domains",
      :pretty_name => "Import Domains from Wwws.io",
      :authors => ["jcran", ],
      :description => "This gathers domains from the wwws.io API.",
      :references => [],
      :type => "import",
      :passive => true,
      :allowed_types => ["String"],
      :example_entities => [{"type" => "String", "details" => {"name" => "com"}}],
      :allowed_options => [
        {:name => "threads", :regex => "integer", :default => 1 }
      ],
      :created_types => ["Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    user = _get_global_config("wwws_io_username")
    pass = _get_global_config("wwws_io_password")
    unless user && pass
      _log_error "No creds?"
      return
    end

    domain_code = _get_entity_name || 503

    downlink="https://domainlists.io/api/full/#{domain_code}/#{user}/#{pass}/"

    _log "Sending #{downlink}"

    f = download_and_store downlink


    # Read and split the file up into a list of domains
    lines = File.open(f,"r").read.split("\n")
    domains = lines.map{|l| l.chomp if l }

    lammylam = lambda { |d|
      #_log "Creating domain: #{d}"
      _create_entity "DnsRecord", { "name" => "#{d}" }
    true
    }

    # use a generic threaded iteration method to create them,
    # with the desired number of threads
    thread_count = _get_option "threads"
    _threaded_iteration(thread_count, domains, lammylam)

  end



end
end
end
