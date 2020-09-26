module Intrigue
module Task
module Enrich
class AzureBLOBT < Intrigue::Task::BaseTask

  def self.metadata
    {
      :name => "enrich/azure_blob",
      :pretty_name => "Enrich Azure BLOB Storage",
      :authors => ["Anas Ben Salah"],
      :description => "Fills in details for an Azure Blob Storage (including open files)",
      :references => [],
      :type => "enrichment",
      :passive => true,
      :allowed_types => ["AzureBLOB"],
      :example_entities => [
        {"type" => "AzureBLOB", "details" => {"name" => "https://test.blob.core.windows.net"}}
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run

    blob_uri = _get_entity_detail("uri") || _get_entity_name
    blob_uri.chomp!("/")

    unless blob_uri =~ /blob.core.windows.net/
      _log_error "Not an Azure Blob link?"
      return
    end

    # DO THE BRUTEFORCE
    # Parses the HTTP reply of a brute-force attempt
    # for each letter of the alphabet...
    get_account_response blob_uri

  end
  end


  def get_account_response(azureblob_uri)

    response = http_request(azureblob_uri)

    return if response.code=="404"


    puts response.reason_phrase

    if (response.reason_phrase.include? "Server failed to authenticate the request")
      puts "Auth-Only Storage Account"
    elsif(response.reason_phrase.include? "The specified account is disabled")
      puts "Disabled Storage Account"
    elsif (response.reason_phrase.include? "Value for one of the query")
      puts "HTTP-OK Storage Account"
      _create_linked_issue("azure_blob_open_publicly", {
        status: "confirmed",
        detailed_description: "This url: #{azure_blob} can be accessed publicly",
        details: {
          uri: azureblob_uri
          }
      })
    elsif (response.reason_phrase.include? "The account being accessed")
      puts "HTTPS-Only Storage Account"
      _create_linked_issue("azure_blob_open_publicly", {
        status: "confirmed",
        detailed_description: "This url: #{azure_blob} can be accessed publicly",
        details: {
          uri: azureblob_uri
          }
      })
    else
      return
    end #end if location

  end # End get_account_response

end
end
end
