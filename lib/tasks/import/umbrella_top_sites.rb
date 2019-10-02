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
      :allowed_options => [],
      :created_types => ["Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    _log_good "Downloading latest file"
    z = download_and_store "http://s3-us-west-1.amazonaws.com/umbrella-static/top-1m.csv.zip"
    # unzip
    _log_good "Extracting into memory"
    Zip::File.open(z) do |zip_file|
      # Handle entries one by one
      zip_file.each do |entry|
        ### Do the thing 
        _log_good "Parsing out domains"
        entry.get_input_stream.read.split("\n").map do |l| 
          domain = l.split(",").last.chomp
          # create entities
          e = _create_entity "Uri", { "name" => "http://#{domain}" }
          _create_entity "Uri", { "name" => "https://#{domain}"}, e
        end
      end
    end
  end


end
end
end
