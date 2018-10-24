module Intrigue
module Task
class SecurityTrailsNameserverSearch < BaseTask

  include Intrigue::Task::SecurityTrails

  def self.metadata
    {
      :name => "security_trails_nameserver_search",
      :pretty_name => "Security Trails Nameserver Search",
      :authors => ["jcran"],
      :description => "This task hits the Security Trails API and finds all domains for a given nameserver.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Nameserver"],
      :example_entities => [{"type" => "Nameserver", "details" => {"name" => "ns1.intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["Domain"]
    }
  end

  def run
    super

    begin
      total_records = []

      # get initial repsonse
      name = _get_entity_name
      resp = st_nameserver_search name

      unless resp
        _log_error "unable to get a response"
        return
      end

      # check if we need to page
      max_pages = resp["meta"]["total_pages"]
      if max_pages > 1
        total_records = resp["records"]
        (2..max_pages).each do |p|

          resp = st_nameserver_search(name,p)
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
