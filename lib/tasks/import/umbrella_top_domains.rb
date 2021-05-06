
module Intrigue
module Task
class ImportUmbrellaTopDomains < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "import/umbrella_top_domains",
      :pretty_name => "Import Umbrella Top Domains",
      :authors => ["jcran", "jgamblin"],
      :description => "This gathers the allocated ipv4 ranges from ARIN and creates NetBlocks.",
      :references => [],
      :type => "import",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [{"type" => "String", "details" => {"name" => "__IGNORE__"}}],
      :allowed_options => [
        {:name => "threads", :regex => "integer", :default => 1 }
      ],
      :created_types => ["Domain"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    _log_good "Downloading latest file"
    z = download_and_store "http://s3-us-west-1.amazonaws.com/umbrella-static/top-1m.csv.zip"

    # domains
    domains = []

    # unzip
    _log_good "Extracting into memory"
    Zip::File.open(z) do |zip_file|

      # Handle entries one by one
      zip_file.each do |entry|

        # Read into memory
        content = entry.get_input_stream.read

        ### Do the thing

        _log_good "Parsing out domains"
        domains = content.split("\n").map{|l| l.split(",").last.chomp }

      end

    end

    # Now really do the thing
    _log_good "Setting up the lambda"
    lammylam = lambda { |d|
      _create_entity "Domain", { "name" => "#{d}" }
    true
    }

    # use a generic threaded iteration method to create them,
    # with the desired number of threads
    _log_good "Fanning out"
    thread_count = _get_option "threads"

    input_queue = Queue.new
    domains.each do |item|
      input_queue << item
    end

    _threaded_iteration(thread_count, input_queue, lammylam)

  end

end
end
end
