module Intrigue
module Task
class SearchAzureBlob < BaseTask

  def self.metadata
    {
      :name => "search_azure_blob",
      :pretty_name => "Search Azure Blob",
      :authors => ["Anas ben salah"],
      :description => "This task takes a UniqueKeyword or Domain name to determine if there is any exposed Azure blob and attempts to lists its files",
      :references => [],
      :type => "Discovery",
      :passive => true,
      :allowed_types => ["UniqueKeyword","Domain"],
      :example_entities => [
        {"type" => "UniqueKeyword", "details" => {"name" => "intrigue"}},
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [
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
    valid_account_list = []

    # get entity details
    if entity_type == "Domain"
      account_name = account_name.split('.')[0]
      _log "Searching results for #{account_name} ..."
    elsif entity_type == "UniqueKeyword"
      _log "Searching results for #{account_name} ..."
    else
      _log_error "Unsupported entity type"
    end

    # Generate blob brute force list
    # Brute force Azure server, get valid accounts for open Blobs and create issues
    valid_account_list = brute_force_blob account_name, blob_url

    # Generate container brute force list
    # Brute force Azure cntainers for listing exposed files and create issues
    brute_force_container valid_account_list

  end # End run



  #Checking for the blob response 
  def check_blob_response (response)
    
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
      #Create an issue if we have a positive response for an open blob
      _create_linked_issue("azure_blob_open_publicly", {
        proof: "This url: #{response.request.base_url} can be accessed publicly",
        status: "confirmed",
        detailed_description: "This url: #{response.request.base_url} can be accessed publicly",
        details: {
          uri: response.request.base_url
          }
      })
      #Extracting valid uri for open blob
      valid_uri = response.request.base_url
    elsif (response.reason.include? "The account being accessed")
      _log "HTTPS-Only Storage Account"
      #Create an issue if we have a positive response for an open blob
      _create_linked_issue("azure_blob_open_publicly", {
        proof: "This url: #{response.request.base_url} can be accessed publicly",
        status: "confirmed",
        detailed_description: "This url: #{response.request.base_url} can be accessed publicly",
        details: {
          uri: response.request.base_url
          }
      })
      #Extracting valid uri for open blob
      valid_uri  = response.request.base_url
    else
      return
    end #end if 

    return response.request.base_url
  end

  # brute force azure server for checking valid blob url
  def brute_force_blob (account_name, blob_url)
    # initializing lists
    valid_account_list=[]
    list_to_bruteforce=["#{account_name}"]

    # Load permutation wordlist
    file = File.open "#{$intrigue_basedir}/data/azure_permutations.json"
    permut = JSON.load file

    # Combining user input and permutations list
    permut["permutations"].each do |p|
      # account_name + keyword
      account = "#{account_name}"+"#{p}"
      list_to_bruteforce.append(account)
      # keyword + account_name
      account = "#{p}"+"#{account_name}"
      list_to_bruteforce.append(account)
    end

    # initializing Queue for handling multi-thread requests 
    work_q = Queue.new

    # push everything into queue
    list_to_bruteforce.each do |b|
      blob_uri = "https://"+"#{b}"+"."+"#{blob_url}"
      work_q.push(blob_uri)
    end

    # run requests and get responses
    responses = make_threaded_http_requests_from_queue(work_q, 20)

    # Creating a list of valid responses   
    responses.each do |r| 
      is_valid_url = check_blob_response r
      if is_valid_url
        valid_account_list.append(is_valid_url)
      end
    end

    #return a list of valid accounts
    return valid_account_list

  end

  # Create a brute list combining valid blob uri and container_brute_force list
  # brute force azure container for extracting files
  def brute_force_container(valid_account_list)
    # initializing list
    container_brute_list=[]
    
    # initializing Queue for handling multi-thread requests
    work_q = Queue.new

    # Load permutation wordlist
    file = File.open "#{$intrigue_basedir}/data/container_brute_force.json"
    container_list = JSON.load file

    # Combining valid account list and permutations list
    valid_account_list.each do |blob_valid_uri|
      container_list["container"].each do |container_name|
        container_uri = "#{blob_valid_uri}"+"/#{container_name}/?comp=list"
        container_brute_list.append(container_uri)
      end
    end

    # push everything into queue
    container_brute_list.each do |c|
      work_q.push(c)
    end

    # return multiples responses 
    responses = make_threaded_http_requests_from_queue(work_q, 20)

    # Brute force azure container for extracting files
    responses.each do |r|
      check_container_response r 
    end 
  end


  # Checking for the container_uri response
  def check_container_response (response)
    # Dealing with types of responses
    if (response.code=="404")
      return
    elsif (response.code=="200")
      all_files = list_container_content response.request.base_url
      #Create an issue if we have a positive response for container uri and exposed files
      _create_linked_issue("azure_blob_exposed_files", {
        status: "confirmed",
        detailed_description: "This container #{response.request.base_url} can be accessed publicly and it exposes files",
        proof: {
          exposed_files: all_files,
          uri: response.request.base_url
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
