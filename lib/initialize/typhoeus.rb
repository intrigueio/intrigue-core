module Typhoeus
  class Response

    # aliases status to code (as a string, since that tis the behavor of )
    def code
      self.response_code.to_s
    end

    def each_header
      self.response_headers.map{|x,y| x }
    end

    def [](key)
      self.response_headers[key]
    end

    def reason
      response_headers.split("\n").first.split(" ")[2..-1].join(" ")
    end

    def body_utf8
      self.body.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').gsub("\u0000", '')
    end

  end
end
