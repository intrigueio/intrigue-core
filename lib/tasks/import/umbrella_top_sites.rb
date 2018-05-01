module Intrigue
module Task
class ImportUmbrellaTopSites < BaseTask

  include Intrigue::Task::Generic
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "import/umbrella_top_sites",
      :pretty_name => "Import Umbrella Top Sites",
      :authors => ["jcran", "jgamblin"],
      :description => "This gathers the allocated ipv4 ranges from ARIN and creates NetBlocks.",
      :references => [],
      :type => "import",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [{"type" => "String", "details" => {"name" => "NA"}}],
      :allowed_options => [
        {:name => "threads", :regex => "integer", :default => 1 },
        {:name => "max_sleep", :regex => "integer", :default => 10 }
      ],
      :created_types => ["NetBlock"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # TODO - this shouldn't be static
    f = download_and_store "https://s3.amazonaws.com/public.intrigue.io/top-1m-2018-04-20.csv"

    # Read and split the file up into a list of domains
    lines = File.open(f,"r").read.split("\n")
    domains = lines.map{|l| l.split(",").last.chomp }

    lammylam = lambda { |d|
      sleep(rand(_get_option("max_sleep")))

      #_log "Creating sites for domain: #{d}"
      #_create_entity "Uri", { "name" => "http://#{d}", "uri"=>"https://#{d}" }
      _create_entity "Uri", { "name" => "https://#{d}", "uri"=>"https://#{d}" }
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
