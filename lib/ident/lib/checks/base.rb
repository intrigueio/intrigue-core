module Intrigue
module Ident
module Check
class Base

  def self.inherited(base)
    CheckFactory.register(base)
  end

  private

    def _body(content)
      content["details"]["hidden_response_data"] || ""
    end

    # matching helpers
    def _first_body_match(content, regex)
      return nil unless content["details"]["hidden_response_data"]
      content["details"]["hidden_response_data"].match(regex)
    end

    def _first_body_capture(content, regex, filter=[])
      return nil unless content["details"]["hidden_response_data"]
      x = content["details"]["hidden_response_data"].match(regex)
      if x
        x = x.captures.first.strip
        filter.each{|f| x.gsub!(f,"") }
        x = x.strip
        return x if x.length > 0
      end
    nil
    end

    def _first_header_match(content, regex)
      return nil unless content["details"]["headers"]
      content["details"]["headers"].match(regex).first
    end

    def _first_header_capture(content,regex, filter=[])
      return nil unless content["details"]["headers"]
      x = content["details"]["headers"].join("\n").match(regex)
      if x
        x = x.captures.first
        filter.each{|f| x.gsub!(f,"") }
        x = x.strip
        return x if x.length > 0
      end
    nil
    end

    def _first_cookie_match(content, regex)
      return nil unless content["details"]["cookies"]
      content["details"]["cookies"].match(regex).first
    end

    def _first_cookie_capture(content, regex, filter=[])
      return nil unless content["details"]["headers"]
      x = content["details"]["cookies"].match(regex)
      if x
        x = x.captures.first.strip
        filter.each{|f| x.gsub!(f,"") }
        x = x.strip
        return x if x.length > 0
      end
    nil
  end

end
end
end
end
