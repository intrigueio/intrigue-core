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
    # check that our regex for the hash matches
    !supported_hash_types.select{|x| x[:regex] =~ name }.empty?
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
