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

      if session # make sure we're enabled

        document = capture_document session, url
        if document
          title = document[:title]
          body = document[:contents]
        else 
          _log "No response"
        end

      else 
        _log "No browser session created. Is the browser enabled in global options?"
      end

    ensure
      destroy_browser_session(session)
    end

    service_name = "trello"

    if body =~ /BoardsMembers/
      _log "The #{name} org exists!"
      _create_normalized_webaccount service_name, name, url

    elsif body =~ /ProfileCardsTeamsActivity/
      _log "The #{name} member account exists!"
      _create_normalized_webaccount service_name, name, url

    else
      _log "Nothing found for #{name}"
    end
  end

end
end
end
