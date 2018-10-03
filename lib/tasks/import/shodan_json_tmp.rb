module Intrigue
module Task
class ImportShodanJson < BaseTask

  include Intrigue::Task::Generic
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "import/shodan_json",
      :pretty_name => "Import Shodan JSON",
      :authors => ["jcran"],
      :description => "This takes a local Shodan file and creates relevant entities.",
      :references => [],
      :type => "import",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [{"type" => "File", "details" => {"name" => "/home/user/file.json"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord", "IpAddress", "Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    f = _get_entity_name

    # Read and split the file up
    begin
      json = JSON.parse (File.open(f,"r").read)
    rescue JSON::ParserError => e
      _log_error "Unable to parse, failing..."
      return
    end





  end



end
end
end
