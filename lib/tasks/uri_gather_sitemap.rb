require "rexml/document"

module Intrigue
class UriGatherRobots  < BaseTask

  include Intrigue::Task::Web

  def metadata
    {
      :name => "uri_gather_sitemap",
      :pretty_name => "URI Gather Sitemap (sitemap.xml)",
      :authors => ["jcran"],
      :description =>   "This task checks for sitemap.xml and adds any URIs it finds",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "attributes" => {"name" => "http://intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["Uri"]
    }
  end

  def run
    super

    uri = _get_entity_attribute "name"

    checks = [{ :path => "sitemap.xml", :signature => "uri" }]

    checks.each do |check|

      # Concat the uri to create the check unless it already looks like a sitemap
      uri = "#{uri}/#{check[:path]}" unless uri =~ /sitemaps?\.xml/

      @task_result.logger.log "Connecting to #{uri}"

      # Grab a known-missing page so we can make sure it's not a
      # 404 disguised as a 200
      test_url = "#{uri}/there-is-no-way-this-exists-#{rand(10000)}"
      missing_page_content = http_get_body test_url

      # Do the request
      content = http_get_body uri

      # Check to make sure this is a legit sitemap
      if content != missing_page_content
        r = REXML::Document.new(content)
        @task_result.logger.log "Processing #{REXML::XPath.each(r, "//loc").count} entities"
        REXML::XPath.each(r, "//loc") do |x|
          # otherwise create a webpate
          _create_entity "Uri", { "name" => x.text, "uri" => x.text  }
        end

      end

    end
  end

end
end
