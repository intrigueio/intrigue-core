module Intrigue
module Task
class PublicTrelloCheck < BaseTask


  def self.metadata
    {
      :name => "public_trello_check",
      :pretty_name => "Public Trello Check",
      :authors => ["jcran","jgamblin"],
      :description => "Checks to see if public Google Groups exist for a given domain",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["String","Organization"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "intrigue"}}
      ],
      :allowed_options => [],
      :created_types => ["TrelloAccount","TrelloOrganization"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name

    uri = "https://trello.com/#{entity_name}"
    session = create_browser_session
    document = capture_document session, uri
    title = document[:title]
    body = document[:contents]

    if body =~ /BoardsMembers/
      _log "The organization exists!"
      _create_entity "TrelloOrganization", {
        "name" => entity_name,
        "uri" => uri
      }
    elsif body =~ /ProfileCardsTeamsActivity/
      _create_entity "TrelloAccount", {
        "name" => entity_name,
        "uri" => uri
      }
    else
      _log "Nothing found..."
    end

  end

end
end
end
