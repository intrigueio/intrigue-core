module Intrigue
module Task
module Enrich
class Nameserver < Intrigue::Task::BaseTask
  include Intrigue::Client::SecurityTrails

  def self.metadata
    {
      :name => "enrich/nameserver",
      :pretty_name => "Enrich Nameserver",
      :authors => ["jcran"],
      :description => "Enrich a nameserver entity",
      :references => [],
      :allowed_types => ["Nameserver"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [{"type" => "Nameserver", "details" => {"name" => "ns1.intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["Domain"]
    }
  end

  def run
    super

    begin
      total_records = []

      entity_name = _get_entity_name

      # get intial response
      resp = st_nameserver_search(entity_name,1)

      unless resp
        _log_error "Unable to get a response"
        return
      end

      # check if we need to page
      max_pages = resp["meta"]["total_pages"]
      if max_pages > 1
        total_records = resp["records"]
        (2..max_pages).each do |p|

          resp = st_nameserver_search(entity_name,p)
          break unless resp

          total_records.concat(resp["records"])
        end
      # if not....
      else
        total_records = resp["records"]
      end

      # create entities
      total_records.each do |x|
        _create_entity "Domain", "name" => "#{x["hostname"]}"
      end

    rescue JSON::ParserError => e
      _log_error "Unable to get a properly formatted response"
    end
  end # end run()

end
end
end
end