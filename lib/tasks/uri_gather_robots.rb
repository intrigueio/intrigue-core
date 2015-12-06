module Intrigue
class UriGatherRobotsTask  < BaseTask

  include Intrigue::Task::Web

  def metadata
    {
      :name => "uri_gather_robots",
      :pretty_name => "URI Gather Robots.txt",
      :authors => ["jcran"],
      :description =>   "This task checks for robots.txt and adds any URIs it finds",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "attributes" => {"name" => "http://intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["Uri"]
    }
  end

  def run
    super

    base_uri = _get_entity_attribute "name"

    checks = [{ :path => "robots.txt" }]

    checks.each do |check|
      # Concat the uri to create the check
      uri = "#{base_uri}/#{check[:path]}"

      @task_result.logger.log "Connecting to #{uri}"

      # Grab a known-missing page so we can make sure it's not a
      # 404 disguised as a 200
      test_url = "#{uri}/there-is-no-way-this-exists-#{rand(10000)}"
      missing_page_content = http_get_body test_url

      # Do the request
      content = http_get_body uri

      return unless content

      @task_result.logger.log "Got result for #{uri}:\n#{content}"

      # Check to make sure this is a legit page, and create an entity if so
      # TODO - improve the checking for wildcard page returns and 404-200's
      if content != missing_page_content

        # for each line of the file
        content.each_line do |line|

          # don't add comments
          next if line =~ /^#/
          next if line =~ /^User-agent/
          next if line =~ /\n/

          # This will work for the following types
          # Disallow: /path/
          # Sitemap: http://site.com/whatever.xml.gz
          if line =~ /Sitemap/i
            path = line.split(" ").last.strip
            full_path = "#{path}"  # Sitemap uri is a full uri

          elsif line =~ /Disallow/i
            path = line.split(":").last.strip
            next if path =~ /^Disallow/i
            full_path = "#{base_uri}#{path}" # disallow is relative

          elsif line =~ /Allow/i
            path = line.split(":").last.strip
            next if path =~ /^Allow/i
            full_path = "#{base_uri}#{path}" # allow is relative
          end

          # if there's a wildcard in the path, it won't be a functional URI
          # example: http://alyaum.com/robots.txt
          #
          #if full_path =~ /\*/
          #  full_path.split("*").first
          #end

          # otherwise create a webpate
          _create_entity "Uri", { "name" => full_path, "uri" => full_path, "detail" => line }
        end
      end
    end
  end

end
end
