module Intrigue
module Task
class ImportUmbrellaTopSites < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "import/umbrella_top_sites",
      :pretty_name => "Import Umbrella Top Domains",
      :authors => ["jcran", "jgamblin"],
      :description => "This gathers the allocated ipv4 ranges from ARIN and creates NetBlocks.",
      :references => [],
      :type => "import",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [{"type" => "String", "details" => {"name" => "NA"}}],
      :allowed_options => [{:name => "threads", :regex => "integer", :default => 1 }],
      :created_types => ["NetBlock"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super
    f = download_and_store "https://s3.amazonaws.com/public.intrigue.io/top-1m-2018-04-20.csv"
    lines = File.open(f,"r").read.split("\n")
    domains = lines.map{|l| l.split(",").last }

    # use a generic threaded iteration method to create them,
    # with the desired number of threads
    thread_count = _get_option "threads"
    _threaded_iteration(thread_count, domains, create_uris)

  end

  def create_dns_record(domain)
    _log "Creating domain: #{domain}"
    _create_entity "DnsRecord", "name" => "#{domain}"
  true
  end


end
end
end
