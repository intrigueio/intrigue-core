module Intrigue
module Task
class ImportDomainlists < BaseTask

  include Intrigue::Task::Generic
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "import/domainlists",
      :pretty_name => "Import Domains from Domainlists",
      :authors => ["jcran", ],
      :description => "This gathers domains from the Domainlists API.",
      :references => [],
      :type => "import",
      :passive => true,
      :allowed_types => ["String"],
      :example_entities => [{"type" => "String", "details" => {"name" => "534"}}],
      :allowed_options => [
        {:name => "threads", :regex => "integer", :default => 1 }
      ],
      :created_types => ["Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    user = _get_task_config("domainlists_username")
    pass = _get_task_config("domainlists_password")
    unless user && pass
      _log_error "No creds?"
      return
    end

    # See: https://domainlists.io/domains-api/
    # 534 - com
    # 928 - gov
    # 675 - edu
    domain_code = _get_entity_name || 534
    downlink = "https://domainlists.io/api/full/#{domain_code}/#{user}/#{pass}/"
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
