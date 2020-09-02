module Excon
  class Response
  
    # aliases status to code (as a string, since that tis the behavor of )
    def code
      self.status.to_s
    end

    def each_header
      self.headers.map{|x,y| x }
    end

    def [](key)
      self.headers[key]
    end

    def body_utf8
      self.body.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    end

  end
end
