module Intrigue
module Task
class ImportDataFile < BaseTask

  include Intrigue::Task::Generic
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "import/data_file",
      :pretty_name => "Import Data File",
      :authors => ["jcran", ],
      :description => "This imports entities from a file.",
      :references => [],
      :type => "import",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [{"type" => "String", "details" => {"name" => "unused"}}],
      :allowed_options => [
        {:name => "entity_type", :regex => "alpha_numeric", :default => "String" },
        {:name => "filename", :regex => "alpha_numeric", :default => "cities.list" },
        {:name => "threads", :regex => "integer", :default => 1 }
      ],
      :created_types => ["*"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    data_type_string = _get_option("entity_type")
    filename = _get_option("filename")

    # Check data type string to make sure we have a valid type
    data_type = Intrigue::EntityManager.resolve_type_from_string data_type_String
    unless data_type # fail if not
      _log_error "Unknown data type: #{data_type_string}, failing"
    end

    # Read and split the file up into a list of domains
    lines = File.open("#{$intrigue_basedir}/data/#{filename}","r").read.split("\n")
    entities = lines.map{|l| l.chomp if l }

    lammylam = lambda { |e|
      #_log "Creating domain: #{d}"
      _create_entity "#{data_type}", { "name" => "#{e}" }
    true
    }

    # use a generic threaded iteration method to create them,
    # with the desired number of threads
    thread_count = _get_option "threads"

    input_queue = Queue.new
    entities.each do |item|
      input_queue << item
    end

    _threaded_iteration(thread_count, entities, lammylam)

  end



end
end
end
