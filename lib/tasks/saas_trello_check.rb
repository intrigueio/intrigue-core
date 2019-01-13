module Intrigue
module Task
class SaasTrelloCheck < BaseTask


  def self.metadata
    {
      :name => "saas_trello_check",
      :pretty_name => "SaaS Trello Check",
      :authors => ["jcran"],
      :description => "Checks to see if Trello account exists for a given domain",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","Organization", "String"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "intrigue"}}
      ],
      :allowed_options => [],
      :created_types => ["WebAccount"],
      :queue => "task_browser"
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    check_and_create entity_name

    # trello strips out periods, so handle dns records differently
    if _get_entity_type_string == "Domain"
      check_and_create entity_name.split(".").first
      check_and_create entity_name.gsub(".","")
    end

  end

  def check_and_create(name)
    url = "https://trello.com/#{name}"

    begin
      session = create_browser_session
      document = capture_document session, url
      title = document[:title]
      body = document[:contents]
    ensure
      destroy_browser_session(session)
    end

    service_name = "trello.com"

    if body =~ /BoardsMembers/
      _log "The #{name} org exists!"
      _create_entity "WebAccount", {
        "name" => "#{service_name}: #{name}",
        "uri" => url,
        "username" => "#{name}",
        "service" => service_name
      }
    elsif body =~ /ProfileCardsTeamsActivity/
      _log "The #{name} member account exists!"
      _create_entity "WebAccount", {
        "name" => "#{service_name}: #{name}",
        "uri" => url,
        "username" => "#{name}",
        "service" => service_names
      }
    else
      _log "Nothing found for #{name}"
    end
  end

end
end
end
