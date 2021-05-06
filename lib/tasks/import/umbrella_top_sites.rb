module Intrigue
module Task
class ImportUmbrellaTopSites < BaseTask

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
      :example_entities => [{"type" => "String", "details" => {"name" => "__IGNORE__"}}],
      :allowed_options => [],
      :created_types => ["Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    _log_good "Downloading latest file"
    z = download_and_store "http://s3-us-west-1.amazonaws.com/umbrella-static/top-1m.csv.zip"

    domains = []
    # unzip
    _log_good "Extracting into memory"
    Zip::File.open(z) do |zip_file|
      # Handle entries one by one
      zip_file.each do |entry|
        ### Do the thing
        _log_good "Parsing out domains"
        entry.get_input_stream.read.split("\n").map do |l|
          # Drop them into an array
          domains << l.split(",").last.chomp
        end
      end
    end

    project = @entity.project
    entity_ids = []

    # Create the entities
    domains.each do |domain|
      entity_ids << Intrigue::EntityManager.create_bulk_entity(project.id,
        "Intrigue::Entity::Uri", "http://#{domain}", {"name" => "http://#{domain}"}).id
    end

    # Now schedule enrichemnt
    entity_ids.each do |eid|
      e = Intrigue::Entity::Uri.first :id => eid
      start_task("task_enrichment", project,nil, "enrich/uri", e, 1, [{"name" => "correlate_endpoints", "value" => false}]) if e
    end

  end


end
end
end
