require "pry"
module Intrigue
module Task
class SearchAzureBlob < BaseTask

  def self.metadata
    {
      :name => "search_azure_blob",
      :pretty_name => "Search Azure Blob",
      :authors => ["Anas ben salah"],
      :description => "This task takes a string or Domain name to determine if there is any exposed Azure blob and lists its files if possible",
      :references => [],
      :type => "Discovery",
      :passive => true,
      :allowed_types => ["String","Domain"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "intrigue"}},
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [
        #{:name => "use_file", :regex => "boolean", :default => false }
      ],
      :created_types => ["AzureBlob"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    #get account_name
    account_name = _get_entity_name
    entity_type = _get_entity_type_string

    # blob Url
    blob_url = 'blob.core.windows.net'

    # Lists
    account_brute_list = []
    valid_account_list = []
    container_list = []

    # get entity details
    if entity_type == "Domain"
      account_name = account_name.split('.', 0)
      _log "Searching results for #{account_name} ..."
    elsif entity_type == "String"
      _log "Searching results for #{account_name} ..."
    else
      _log_error "Unsupported entity type"
    end

    # Generate blob brute force list
    account_brute_list = brute_force_list account_name
    # Brute force Azure server, get valid accounts for open Blobs and create issues
    valid_account_list = brute_force_blob account_brute_list, blob_url
    # Generate container brute force list
    container_list = container_brute_list valid_account_list
    # Brute force Azure server for listing exposed files in containers and create issues
    brute_force_container container_list

  end # End run

  #Checking for the blob response using a list of potential words
  def check_blob_response (blob_uri)
    response = http_request :get, blob_uri
    # Dealing with types of responses
    if (response.code=="0")
      return
    elsif (response.code=="404")
      return
    elsif (response.reason.include? "Server failed to authenticate the request")
      _log "Auth-Only Storage Account"
    elsif(response.reason.include? "The specified account is disabled")
      _log "Disabled Storage Account"
    elsif (response.reason.include? "Value for one of the query")
      _log "HTTP-OK Storage Account"
      #_create_entity("AzureBlob", {"account_name" => "#{account_name}","uri" => "#{blob_uri}"})
      #Create an issue if we have a positive response for an open blob
      _create_linked_issue("azure_blob_open_publicly", {
        status: "confirmed",
        detailed_description: "This url: #{blob_uri} can be accessed publicly",
        details: {
          uri: blob_uri
          }
      })
      #Extracting valid uri for open blob
      valid_uri = blob_uri
    elsif (response.reason.include? "The account being accessed")
      _log "HTTPS-Only Storage Account"
      #_create_entity("AzureBlob", {"account_name" => "#{account_name}","uri" => "#{blob_uri}"})
      #Create an issue if we have a positive response for an open blob
      _create_linked_issue("azure_blob_open_publicly", {
        status: "confirmed",
        detailed_description: "This url: #{blob_uri} can be accessed publicly",
        details: {
          uri: blob_uri
          }
      })
      #Extracting valid uri for open blob
      valid_uri  = blob_uri
    else
      return
    end #end if location

    return valid_uri
  end

  #Create a brute list combining user input and permutations list
  def brute_force_list (account_name)
    account_brute_list=["#{account_name}"]
    file = File.open "#{$intrigue_basedir}/data/permutations.json"
    permut = JSON.load file
    permut["permutations"].each do |p|
      # account_name + keyword
      account = "#{account_name}"+"#{p}"
      account_brute_list.append(account)
      # keyword + account_name
      account = "#{p}"+"#{account_name}"
      account_brute_list.append(account)
    end

    return account_brute_list
  end

  # brute force azure server for checking valid blob url
  def brute_force_blob (account_brute_list, blob_url)
    valid_account_list = []
    account_brute_list.each do |account|
      blob_uri = "https://"+"#{account}"+"."+"#{blob_url}"
      valid = check_blob_response blob_uri
      if valid != nil
        valid_account_list.append(valid)
      end
    end
    #return a list of valid accounts
    return valid_account_list
  end


  #Create a brute list combining valid blob uri and container_brute_force list
  def container_brute_list(valid_account_list)
    container_brute_list=[]
    file = File.open "#{$intrigue_basedir}/data/container_brute_force.json"
    container_list = JSON.load file
    valid_account_list.each do |blob_valid_uri|
      container_list["container"].each do |container_name|
        container_uri = "#{blob_valid_uri}"+"/#{container_name}/?comp=list"
        container_brute_list.append(container_uri)
      end
    end
    return container_brute_list
  end


  # brute force azure server for extracting files
  def brute_force_container (container_brute_list)
    container_brute_list.each do |container_uri|
      check_container_response container_uri
    end
  end

  # Checking for the container_uri response
  def check_container_response (container_uri)
    response = http_request :get, container_uri
    # Dealing with types of responses
    if (response.code=="404")
      return
    elsif (response.code=="200")
      all_files = list_container_content container_uri
      #Create an issue if we have a positive response for container uri and exposed files
      _create_linked_issue("azure_blob_exposed_files", {
        status: "confirmed",
        detailed_description: "This container #{container_uri} can be accessed publicly and it exposes files",
        details: {
          exposed_files: all_files,
          uri: container_uri
          }
      })
    end
  end

  # Lisitng all files in the container
  def list_container_content (container_uri)
    all_files =[]
    # Parse Webpage response and extracting files details
    doc = Nokogiri::XML(URI.open("#{container_uri}"))
    doc.xpath("//Blob").each do |item|
      # look at each item
      name = item.xpath("Name").text
      url = item.xpath("Url").text
      size = item.xpath("Size").text.to_i
      # add to our array
      all_files << { :name=>"#{name}", :url => "#{url}", :size => "#{size}" }
    end
    return all_files
  end

end
end
end
