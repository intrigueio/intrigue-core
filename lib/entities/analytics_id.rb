module Intrigue
module Entity
class AnalyticsId < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "AnalyticsId",
      :description => "Analytics ID (Google etc)",
      :user_creatable => true,
      :example => "UA-34505845"
    }
  end

  def validate_entity
    # check that our regex for the hash matches
    supported_type = supported_hash_types.select{|x| x[:regex] =~ name }
    valid = !supported_type.empty?
    
    if valid
      # set the detail here 
      set_detail("analytics_source", supported_type.first[:analytics_source] )
    end

  valid 
  end

  # just a list of supported types and their regexen
  def supported_hash_types
    [
      { analytics_source:"google_analytics", regex: /^UA-.\d*$/i },
      { analytics_source:"google_adsense", regex: /^pub-.\d*$/},
      { analytics_source:"intercom", regex: /^[\w\d]{0,8}$/}
    ]
  end

end
end
end
