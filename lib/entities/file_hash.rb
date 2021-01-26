module Intrigue
module Entity
class FileHash < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "FileHash",
      :description => "A hash of a file. SHA1 and MD5 supported.",
      :user_creatable => true,
      :example => "912ec803b2ce49e4a541068d495ab570"
    }
  end

  # just a list of supported types and their regexen
  def self.supported_hash_types
    [
      { type:"md5", regex: /^[a-f0-9]{5,32}$/},
      { type:"sha1", regex: /^[a-f0-9]{5,40}$/},
      { type:"sha2-256", regex: /^\b[A-Fa-f0-9]{64}\b$/}
    ]
  end

  def validate_entity
    # check that our regex for the hash matches
    !self.class.supported_hash_types.select{|x| x[:regex].match(name) }.empty?
  end

  def scoped?
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)
  
  true
  end

end
end
end
