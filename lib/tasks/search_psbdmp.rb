module Intrigue
module Task
class SearchPsbdmp < BaseTask


  def self.metadata
    {
      :name => "search_psbdmp",
      :pretty_name => "Search Psbdmp",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits the Psbdmp API, looking for dump(s) using a Domain, an EmailAddress or UniqueKeyword",
      :references => ["https://psbdmp.ws/api"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain", "EmailAddress", "UniqueKeyword"],
      :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "parse_entities", :regex=> "boolean", :default => false },
      ],
      :created_types => ["CreditCard"]
    }
  end


  ## Default method, subclasses must override this
  def run
    super

    high_severity_keywords = [
      /account/,
      /breach/,
      /CreditCard/i,
      /cvv/,
      /hack/,
      /password/,
      /\A[\d+\s\-]{9,20}\z/,
      /\b[\d+\s\-]{9,20}\b/
    ]

    #get entity name
    entity_name = _get_entity_name

    #headers
    headers = { "Accept" =>  "application/json" }

    # Get responce
    response = http_get_body("https://psbdmp.ws/api/v3/search/#{entity_name}",nil,headers)
    result = JSON.parse(response)

    unless result["data"]
      _log_error "Failed to get a result"
      return
    end

    # continuing on
    result["data"].each do |e|

      # get pastebin uri
      paste_uri = "https://pastebin.com/#{e["id"]}"

      response_body = http_get_body(paste_uri)

      if _get_option("parse_entities")
        parse_and_create_entities_from_content(paste_uri, response_body)
      end

      # Create an issue if we have visible data
      if !response_body.include? "Forbidden (#403)" and !response_body.include? "Not Found (#404)"

        issue_hash = { source: paste_uri, proof: response_body }

        # Check for specific keyword if it is included in the paste to increase the severity level
        if !high_severity_keywords.select{|x| response_body =~ x }.empty?
          # create linked issue with a higher severity
          issue_hash.merge!(severity: 3)
        end

        _create_linked_issue("suspicious_pastebin", issue_hash)

      end
    end
  end #end run


end
end
end
