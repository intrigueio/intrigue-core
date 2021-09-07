class CoreApp < Sinatra::Base

  post "/api/v1/entity" do

    content_type "application/json"

    halt_unless_authenticated!

    # For post requests with a json body, just stick it in params
    # don't clobber params, stick it in its own object
    json = get_json_body
    entities = json["entities"]

    out  = []
    entities.each do |entity|

      entity_type = entity["type"]
      entity_name = entity["name"]

      # Pre-process and remove all fully qualified entities
      # (this will accept both Domain and Intrigue::Entity::Domain as "Domain")
      if entity_type =~ /::/
        entity_type = entity_type.split(":").last
      end

      out << get_claimed_status(entity_type, entity_name)

    end

  wrapped_api_response, nil, out
  end

end