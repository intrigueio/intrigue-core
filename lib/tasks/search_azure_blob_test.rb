module Intrigue
module Task
class SearchAzureBlobTEST < BaseTask

  def self.metadata
    {
      :name => "search_azure_blob_test",
      :pretty_name => "Search Azure Blob TEST",
      :authors => ["Anas ben salah"],
      :description => "This task simply creates an entity.",
      :references => [],
      :type => "Discovery",
      :passive => true,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://test.bah"}}
      ],
      :allowed_options => [],
      :created_types => ["AzureBlob"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super
    blob = []
    #blob_uri = "https://intriguetest.blob.core.windows.net/test/?comp=list"
    require 'open-uri'
    #doc = Nokogiri::HTML(URI.open("http://www.threescompany.com/"))

    # doc = Nokogiri::XML(URI.open("https://intriguetest.blob.core.windows.net/test/?comp=list"))
    # blob = doc.xpath("//Name")
    # puts "*******************"
    # puts blob
    # puts "*******************"
    # puts blob.each do |item|
    #   puts "*******************"
    #   puts item
    #   puts "*******************"
    # end

    all_files =[]
    doc = Nokogiri::XML(URI.open("https://intriguetest.blob.core.windows.net/test/?comp=list"))
    doc.xpath("//Blob").each do |item|
      # look at each item
      name = item.xpath("Name").text
      puts name
      url = item.xpath("Url").text
      puts url
      size = item.xpath("Size").text.to_i
      puts size
      # add to our array
      all_files << { :name=>"#{name}", :url => "#{url}", :size => "#{size}" }
  end

  all_files.each do |element|
    element.each do |key, value|
       puts "key: #{key}, value: #{value}"
    end
  end

end
  ## TODO
  #def brute_force_container (blob_uri, brute_list)
  #end

  # Still in testing phase but this dunction needs response coming from def brute_force_container
  #def check_container_response (response)
  #
  #end

  #def list_container_content (response)
  #end


end
end
end
