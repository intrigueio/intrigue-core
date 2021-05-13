module Intrigue
module Entity
class UniqueToken < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "UniqueToken",
      description: "An api key or analytics id",
      user_creatable: true,
      example: "UA-34505845"
    }
  end

  # just a list of supported types and their regexen
  # Handy: https://github.com/odomojuli/RegExAPI
  # Also Handy: https://github.com/projectdiscovery/nuclei-templates/blob/master/tokens/credentials-disclosure.yaml
  # Also Handy: https://raw.githubusercontent.com/random-robbie/keywords/master/keywords.txt
  # Also Handy: https://gist.github.com/nullenc0de/2473b1d49dfe4b94088304d542eb3760
  def self.supported_token_types
    tokens = JSON.parse(File.read(
      "#{$intrigue_basedir}/data/token_patterns.json"))

    # return
    return tokens
  end

  def validate_entity

    # check that our regex for the hash matches
    #supported_type = self.class.supported_token_types.find{ |p|
    #  regex = p["regex"] || p[:regex]
    #  regex = Regexp.new(regex) unless regex.kind_of?(Regexp)
    #  name.match(regex)
    #}

    #if supported_type
    #  # set the detail here
    #  set_detail("provider", supported_type[:provider] || supported_type["provider"] )
    #  set_detail("sensitive", supported_type[:sensitive] || supported_type["sensitive"] )
    #end

  #!supported_type.nil?
  true
  end

  def scoped?
    return true if self.allow_list || self.project.allow_list_entity?(self)
    return false if self.deny_list || self.project.deny_list_entity?(self)

  true # otherwise just default to true
  end

  def enrichment_tasks
    ["enrich/unique_token"]
  end

end
end
end
