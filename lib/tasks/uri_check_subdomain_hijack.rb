module Intrigue
module Task
class UriCheckSudomainHijack  < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_check_subdomain_hijack",
      :pretty_name => "URI Check Subdomain Hijack",
      :authors => ["jcran"],
      :description =>   "This task checks for a specific string on a matched uri, indicating that it's a hijackable domain",
      :references => ["https://github.com/EdOverflow/can-i-take-over-xyz"],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "details" => {"name" => "http://www.intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["Finding"]
    }
  end

  def run
    super

    uri = _get_entity_name
    response = http_get(uri)

      if response =~ /The specified bucket does not exist/
        _create_hijack_finding "AWS"
      elsif response =~ /No such app/
        _create_hijack_finding "Heroku"
      elsif response =~ /No settings were found for this company:/
        _create_hijack_finding "Help Scout"
      elsif response =~ /We could not find what you're looking for./
        _create_hijack_finding "Help Juice"
      elsif response =~ /is not a registered InCloud YouTrack/
        _create_hijack_finding "JetBrains"
      elsif response =~ /Unrecognized domain/
        _create_hijack_finding "Mashery"
      elsif response =~ /Project doesnt exist... yet!s/
        _create_hijack_finding "Readme.io"

      end
  end #end run

  def create_hijack_finding source
    _create_entity "Finding", {
      "name" => "#{source} Subdomain Takeover: #{uri}",
      "uri" => "#{uri}",
      "severity" => "high",
      "status" => "potential"
    }
  end

end
end
end
