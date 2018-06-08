module Intrigue
module Task
class PublicTrelloCheck < BaseTask


  def self.metadata
    {
      :name => "public_trello_check",
      :pretty_name => "Public Trello Check",
      :authors => ["jcran"],
      :description => "Checks to see if public Google Groups exist for a given domain",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord","Organization", "String"],
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
    check_and_create entity_name

    # trello strips out periods, so handle dns records differently
    if _get_entity_type_string == "DnsRecord"
      check_and_create entity_name.split(".").first
      check_and_create entity_name.gsub(".","")
    end

  end


  def check_and_create(name)
    uri = "https://trello.com/#{name}"
    session = create_browser_session
    document = capture_document session, uri
    title = document[:title]
    body = document[:contents]

    if body =~ /BoardsMembers/
      _log "The #{name} org exists!"
      _create_entity "TrelloOrganization", {
        "name" => name,
        "uri" => uri
      }
    elsif body =~ /ProfileCardsTeamsActivity/
      _log "The #{name} member account exists!"
      _create_entity "TrelloAccount", {
        "name" => name,
        "uri" => uri
      }
    else
      _log "Nothing found for #{name}"
    end
  end

end
end
end
