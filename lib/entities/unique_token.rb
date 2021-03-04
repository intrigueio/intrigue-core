module Intrigue
module Entity
class UniqueToken < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "UniqueToken",
      :description => "Unique Token - could be api key or analytics id",
      :user_creatable => true,
      :example => "UA-34505845"
    }
  end

  # just a list of supported types and their regexen
  # Handy: https://github.com/odomojuli/RegExAPI
  # Also Handy: https://github.com/projectdiscovery/nuclei-templates/blob/master/tokens/credentials-disclosure.yaml
  # Also Handy: https://raw.githubusercontent.com/random-robbie/keywords/master/keywords.txt
  # Also Handy: https://gist.github.com/nullenc0de/2473b1d49dfe4b94088304d542eb3760
  def self.supported_token_types
    
    tokens = [
      { 
        "provider" => "aws_access_key", 
        "regex" => /^(A3T[A-Z0-9]|AKIA|AGPA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Za-z0-9]{16}$/i, 
        "matcher" =>  /((A3T[A-Z0-9]|AKIA|AGPA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Za-z0-9]{16})/, 
        "sensitive" =>  true 
      },
      { 
        "provider" => "amazon_mws", 
        "regex" => /^amzn\\.mws\\.[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i, 
        "matcher" =>  /(amzn\\.mws\\.[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/i, 
        "sensitive" =>  true 
      },
      { 
        "provider" => "google_adsense", 
        "regex" => /^pub-\d+$/i, 
        "matcher" =>  /(pub-\d+)/i, 
        "sensitive" =>  false 
      },
      {
        "provider" => "google_analytics", 
        "regex" => /^UA-[\d\-]+$/i, 
        "matcher" =>  /(UA-[\d\-]+)/i, 
        "sensitive" =>  false 
      },
      { 
        "provider" => "google_api", 
        "regex" => /^AIza[0-9A-Za-z\\-_]{35}$/, 
        "matcher" =>  /[\"\'\=](AIza[0-9A-Za-z\\-_]{35})/i, 
        "sensitive" =>  true 
      },
      { 
        "provider" => "http_user", 
        "regex" => /^[A-Za-z0-9\-_:\.~]+@.*$/i, 
        "matcher" =>  /[ftp|ftps|http|https]:\/\/([A-Za-z0-9\-_\.~]+)[@]/i, 
        "sensitive" =>  true 
      },
      { 
        "provider" => "http_user_pass", 
        "regex" => /^[A-Za-z0-9\-_:\.~]+:[A-Za-z0-9\-_:\.~]+$/i, 
        "matcher" =>  /[ftp|ftps|http|https]:\/\/([A-Za-z0-9\-_\.~]+:[A-Za-z0-9\-_\.~]+)[@]/i, 
        "sensitive" =>  true 
      },
      { 
        "provider" => "hotjar", 
        "regex" => /^[\d+]$/, 
        "matcher" =>  /_hjSettings=\{hjid:([\d+]),/i, 
        "sensitive" =>  false 
      },
      { 
        "provider" => "intercom", 
        "regex" => /^[\w\d]{0,8}$/, 
        "matcher" =>  /app_id: \"([\w\d]{0,8})\"\,/i, 
        "sensitive" =>  false 
      },
      { 
        "provider" => "mailchimp", 
        "regex" => /^[0-9a-f]{32}-us[0-9]{1,2}$/, 
        "matcher" =>  /[\"\'\=]([0-9a-f]{32}-us[0-9]{1,2})/i, 
        "sensitive" =>  true 
      },    
      { 
        "provider" => "slack_person", 
        "regex" => /^xoxp-[0-9A-Za-z\\-]{72}$/, 
        "matcher" =>  /[\"\'\=](xoxp-[0-9A-Za-z\\-]{72})/i, 
        "sensitive" =>  true 
      },
      { 
        "provider" => "slack_bot", 
        "regex" => /^xoxb-[0-9A-Za-z\\-]{51}$/, 
        "matcher" =>  /[\"\'\=](xoxp-[0-9A-Za-z\\-]{51})/i, 
        "sensitive" =>  true 
      }
    ]

    addtl_tokens = JSON.parse(File.read(
      "#{$intrigue_basedir}/data/token_patterns.json"))

  # return both       
  tokens.concat(addtl_tokens)
  end
  
  def validate_entity
    # check that our regex for the hash matches
    supported_type = self.class.supported_token_types.select{ |x| 
      regex = x["regex"]; regex = Regexp.new(regex) unless regex.kind_of?(Regexp)
      regex =~ name 
    }

    valid = !supported_type.empty?
    
    if valid
      # set the detail here 
      set_detail("provider", supported_type.first["provider"] )
      set_detail("sensitive", supported_type.first["sensitive"] )
    end
    
  valid 
  end

  def scoped?
    return true if self.allow_list
    return false if self.deny_list
  
  true # otherwise just default to true
  end

  def enrichment_tasks
    ["enrich/unique_token"]
  end

end
end
end
