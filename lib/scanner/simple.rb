module Intrigue
module Scanner
module Strategy

  class Base

    def _start_task

    end

    # List of prohibited entities - returns true or false
    def is_prohibited entity

      #puts "Checking is_prohibited #{entity}"

      if entity["type"] == "NetBlock"
        cidr = entity["attributes"]["name"].split("/").last.to_i
        return true unless cidr >= 22
      else
        return true if (  entity["attributes"]["name"] =~ /google/             ||
                          entity["attributes"]["name"] =~ /g.co/               ||
                          entity["attributes"]["name"] =~ /goo.gl/             ||
                          entity["attributes"]["name"] =~ /android/            ||
                          entity["attributes"]["name"] =~ /urchin/             ||
                          entity["attributes"]["name"] =~ /youtube/            ||
                          entity["attributes"]["name"] =~ /schema.org/         ||
                          entity["attributes"]["description"] =~ /schema.org/  ||
                          entity["attributes"]["name"] =~ /microsoft.com/      ||
                          #entity["attributes"]["name"] =~ /yahoo.com/          ||
                          entity["attributes"]["name"] =~ /facebook.com/       ||
                          entity["attributes"]["name"] =~ /cloudfront.net/     ||
                          entity["attributes"]["name"] =~ /twitter.com/        ||
                          entity["attributes"]["name"] =~ /w3.org/             ||
                          entity["attributes"]["name"] =~ /akamai/             ||
                          entity["attributes"]["name"] =~ /akamaitechnologies/ ||
                          entity["attributes"]["name"] =~ /amazonaws/          ||
                          entity["attributes"]["name"] == "feeds2.feedburner.com")
      end
    false
    end

  end

  class SimpleStrategy < Base

    def recurse

    end

  end
end
end
end
