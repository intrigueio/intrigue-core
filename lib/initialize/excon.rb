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

  end
end
