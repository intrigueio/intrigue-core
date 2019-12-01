module Intrigue
module Entity
class FileHash < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "FileHash",
      :description => "A hash of a file. SHA1 and MD5 supported.",
      :user_creatable => true,
      :example => "912ec803b2ce49e4a541068d495ab570"
    }
  end

  def validate_entity
    # check that we know the name of this hash type
    supported_hash_types.map{|x| x[:type] }.include?(name) &&
    # and that our regex for the hash matches
    supported_hash_types.map{|x| x[:regex] }.include?(details["hash_type"])
  end

  # just a list of supported types and their regexen
  def supported_hash_types
    [
      { type:"md5", regex: /^[a-f0-9]{5,32}$/},
      { type:"sha1", regex: /^[a-f0-9]{5,40}$/}
    ]
  end

end
end
end
