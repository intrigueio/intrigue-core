module Intrigue
class UriGatherRobotsTask  < BaseTask

  include Intrigue::Task::Web

  def self.metadata
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

    base_uri = _get_entity_name

    checks = [{ :path => "robots.txt" }]

    checks.each do |check|
      # Concat the uri to create the check
      uri = "#{base_uri}/#{check[:path]}"

      # Grab a known-missing page so we can make sure it's not a
      # 404 disguised as a 200
      test_url = "#{base_uri}/there-is-no-way-this-exists-#{rand(1000000)}"
      _log "Checking for missing page: #{test_url}"
      missing_page_content = http_get_body test_url

      unless missing_page_content # fail if we don't get a response
        _log "Unable to retrieve missing page content"
      #  return
      end

      # Do the request
      _log "Connecting to #{uri}"
      content = http_get_body uri

      unless content # fail if we don't get a response
        _log "Unable to retrieve #{uri}"
        return
      end

      _log "Got result for #{uri}:\n#{content}"

      # Check to make sure this is a legit page, and create an entity if so
      # TODO - improve the checking for wildcard page returns and 404-200's
      if content != missing_page_content

        # Content must contain a user-agent directive: http://www.robotstxt.org/orig.html
        unless content =~ /User-agent/i
          _log_error "This content does not include one or more User-agent directives. Skipping"
          return
        end

        # for each line of the file
        content.each_line do |line|

          # don't add comments
          next if line =~ /^#/              # skip comments
          next if line =~ /^User-agent/i    # we don't care about agents for now
          next if line =~ /^\n$/            # skip newlines
          next if line =~ /^\r\n$/          # skip windows newlines
          #next if line =~ /^<html$/i        # skip html (shouldn't make it through the User-agent content check but *shrug*)

          # This will work for the following types
          # Disallow: /path/
          # Allow: /path
          # Sitemap: http://site.com/whatever.xml.gz
          if line =~ /Sitemap/i
            path = line.split(":").last.strip
            next if path =~ /^Sitemap/i
            full_path = "#{path}"  # Sitemap uri should be a full uri
          elsif line =~ /Disallow/i
            path = line.split(":").last.strip
            next if path =~ /^Disallow/i
            full_path = "#{base_uri}#{path}" # disallow is relative uri
          elsif line =~ /Allow/i
            path = line.split(":").last.strip
            next if path =~ /^Allow/i
            full_path = "#{base_uri}#{path}" # allow is relative uri
          end

          # if there's a wildcard in the path, it won't be a functional URI
          # example: http://alyaum.com/robots.txt
          #
          #if full_path =~ /\*/
          #  full_path.split("*").first
          #end

          # Create the entity
          _create_entity "Uri", { "name" => full_path, "uri" => full_path, "detail" => line }
        end
      end
    end
  end

end
end
