class Array

  def sanitize_unicode
    self.map do |x|

      if x.kind_of? String
        x.encode("UTF-8", { :undef => :replace,
                            :invalid => :replace,
                            :replace => "?" })
      else
        x.inspect.encode("UTF-8", { :undef => :replace,
                            :invalid => :replace,
                            :replace => "?" })

      end
    end
  end

end
